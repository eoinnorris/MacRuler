//
//  StreamCaptureObserver.swift
//  MacRuler
//
//  Created by Eoin Kortext on 15/03/2026.
//

import AppKit
@preconcurrency import CoreMedia
@preconcurrency import CoreVideo
@preconcurrency import ScreenCaptureKit
import SwiftUI


@Observable
@MainActor
final class StreamCaptureObserver: NSObject {
   var frameImage: CGImage?
    var latestPixelBuffer: CVPixelBuffer?
    var latestFrameSequence: UInt64 = 0
    var isStreamLive = false

    private let captureQueue = DispatchQueue(label: "ScreenCaptureMagnifier.Capture")
    private var stream: SCStream?
    private var configuration = SCStreamConfiguration()
    private var contentFilter: SCContentFilter?
    private var isRunning = false
    private var currentCaptureRect: CGRect = .zero
    private var screenScale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var pauseTask: Task<Void, Never>?

    override init() {
        super.init()
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        sleepObserver = workspaceCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if let localSelf = self {
                Task { @MainActor in
                    localSelf.pauseCapture()
                }
            }
        }
        wakeObserver = workspaceCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if let localSelf = self {
                Task { @MainActor in
                    localSelf.restartCapture()
                }
            }
        }
    }

    @MainActor
    deinit {
        pauseTask?.cancel()
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        if let sleepObserver {
            workspaceCenter.removeObserver(sleepObserver)
        }
        if let wakeObserver {
            workspaceCenter.removeObserver(wakeObserver)
        }
    }

    func start() async {
        guard !isRunning else { return }
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else { return }
            let ownBundleIdentifier = Bundle.main.bundleIdentifier
            let ownApplications = content.applications.filter { app in
                app.bundleIdentifier == ownBundleIdentifier
            }
            contentFilter = SCContentFilter(
                display: display,
                excludingApplications: ownApplications,
                exceptingWindows: []
            )
            configureStream()
            guard let contentFilter else { return }
            let stream = SCStream(filter: contentFilter, configuration: configuration, delegate: self)
            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: captureQueue)
            try await stream.startCapture()
            self.stream = stream
            isRunning = true
            isStreamLive = true
        } catch {
            isStreamLive = false
            NSLog("Failed to start ScreenCaptureKit stream: \(error.localizedDescription)")
        }
    }

    func stop() {
        pauseTask?.cancel()
        pauseTask = nil
        guard isRunning, let stream else { return }
        captureQueue.async {
            stream.stopCapture { error in
                if let error {
                    NSLog("Failed to stop ScreenCaptureKit stream: \(error.localizedDescription)")
                }
            }
        }
        isRunning = false
        isStreamLive = false
    }

    func pauseCapture() {
        pauseTask?.cancel()
        pauseTask = nil
        guard isRunning || stream != nil else { return }
        let stream = stream
        captureQueue.async {
            stream?.stopCapture { error in
                if let error {
                    NSLog("Failed to stop ScreenCaptureKit stream: \(error.localizedDescription)")
                }
            }
        }
        self.stream = nil
        isRunning = false
        isStreamLive = false
    }

    func restartCapture() {
        pauseTask?.cancel()
        pauseTask = nil
        stream = nil
        contentFilter = nil
        isRunning = false
        isStreamLive = false
        Task { @MainActor in
            await start()
        }
    }

    func pauseCapture(after seconds: TimeInterval) {
        pauseTask?.cancel()
        guard isStreamLive else { return }
        pauseTask = Task { [weak self] in
            let durationInNanoseconds = UInt64(seconds * 1_000_000_000)
            let sleepDuration = Duration.nanoseconds(Int64(durationInNanoseconds))
            try? await Task.sleep(for: sleepDuration)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.pauseCapture()
            }
        }
    }

    func updateCaptureRect(centeredOn rulerFrame: CGRect, screenBound: CGRect) {
        guard rulerFrame != .zero else { return }
        let SCRect = Constants.globalRectToSCRect(rulerFrame, containerHeight: screenBound.height)
        updateCaptureRect(SCRect)
    }

    private func updateCaptureRect(_ rect: CGRect) {
        guard rect != currentCaptureRect else { return }
        currentCaptureRect = rect
        configuration.sourceRect = rect
        configuration.scalesToFit = false
        configuration.width = Int(rect.width * screenScale)
        configuration.height = Int(rect.height * screenScale)
        if let stream {
            stream.updateConfiguration(configuration) { error in
                if let error {
                    NSLog("Failed to update ScreenCaptureKit configuration: \(error.localizedDescription)")
                }
            }
        }
    }

    private func configureStream() {
        configuration.queueDepth = 4
        configuration.minimumFrameInterval = CMTime(value: .zero, timescale: 60)
        configuration.showsCursor = false
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        if currentCaptureRect == .zero {
            currentCaptureRect = CGRect(x: 0, y: 0, width: 120, height: 120)
        }
        configuration.sourceRect = currentCaptureRect
        configuration.width = Int(currentCaptureRect.width * screenScale )
        configuration.height = Int(currentCaptureRect.height * screenScale)
    }
}

extension StreamCaptureObserver: SCStreamOutput {
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen,
              let pixelBuffer = sampleBuffer.imageBuffer else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        Task { @MainActor [weak self] in
            self?.frameImage = cgImage
            self?.latestPixelBuffer = pixelBuffer
            self?.latestFrameSequence &+= 1
            self?.isStreamLive = true
        }
    }
}

extension StreamCaptureObserver: SCStreamDelegate {
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        NSLog("ScreenCaptureKit stream stopped: \(error.localizedDescription)")
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.isRunning = false
            self.isStreamLive = false
            self.stream = nil
            self.contentFilter = nil
        }
    }
}
