//
//  ScreenCaptureMagnifier.swift
//  MacRuler
//
//  Created by Eoin Kortext on 29/01/2026.
//

import AppKit
import CoreMedia
@preconcurrency import ScreenCaptureKit
import SwiftUI

@Observable
final class RulerMagnifierController: NSObject {
   var frameImage: CGImage?

    private let captureQueue = DispatchQueue(label: "ScreenCaptureMagnifier.Capture")
    private let ciContext = CIContext()
    private var stream: SCStream?
    private var configuration = SCStreamConfiguration()
    private var contentFilter: SCContentFilter?
    private var isRunning = false
    private var currentCaptureRect: CGRect = .zero
    private var screenScale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0

    func start() async {
        guard !isRunning else { return }
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else { return }
            contentFilter = SCContentFilter(display: display, excludingWindows: [])
            configureStream()
            guard let contentFilter else { return }
            let stream = SCStream(filter: contentFilter, configuration: configuration, delegate: self)
            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: captureQueue)
            try await stream.startCapture()
            self.stream = stream
            isRunning = true
        } catch {
            NSLog("Failed to start ScreenCaptureKit stream: \(error.localizedDescription)")
        }
    }

    func stop() {
        guard isRunning, let stream else { return }
        captureQueue.async {
            stream.stopCapture { error in
                if let error {
                    NSLog("Failed to stop ScreenCaptureKit stream: \(error.localizedDescription)")
                }
            }
        }
        isRunning = false
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
        configuration.minimumFrameInterval = CMTime(value: 5, timescale: 60)
        configuration.showsCursor = false
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        if currentCaptureRect == .zero {
            currentCaptureRect = CGRect(x: 0, y: 0, width: 120, height: 120)
        }
        configuration.sourceRect = currentCaptureRect
        configuration.width = Int(currentCaptureRect.width * screenScale * 4.0)
        configuration.height = Int(currentCaptureRect.height * screenScale * 4.0)
    }
}

extension RulerMagnifierController: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen,
              let pixelBuffer = sampleBuffer.imageBuffer else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        Task { @MainActor in
            frameImage = cgImage
        }
    }
}

extension RulerMagnifierController: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        NSLog("ScreenCaptureKit stream stopped: \(error.localizedDescription)")
    }
}

struct RulerMagnifierView: View {
    let magnifierSize: CGFloat
    @Bindable var viewModel: MagnificationViewModel
    @State private var controller = RulerMagnifierController()

    var body: some View {
        ZStack {
            if let frameImage = controller.frameImage {
                Image(decorative: frameImage, scale: 4.0)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.black.opacity(0.2)
            }
        }
//        .frame(width: magnifierSize, height: magnifierSize)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            Task {
                await controller.start()
                controller.updateCaptureRect(centeredOn: viewModel.dancingAntsFrame,
                                             screenBound: viewModel.screen?.frame ?? CGRect.zero)
            }
        }
        .onDisappear {
            controller.stop()
        }

        .onChange(of: viewModel.dancingAntsFrame) { _, newValue in
            controller.updateCaptureRect(centeredOn: newValue,
                                         screenBound: viewModel.screen?.frame ?? CGRect.zero)
        }
    }
}

struct RulerFrameReader: NSViewRepresentable {
    var onFrameChange: (CGRect, NSScreen?) -> Void

    func makeNSView(context: Context) -> FrameReportingView {
        let view = FrameReportingView()
        view.onFrameChange = onFrameChange
        return view
    }

    func updateNSView(_ nsView: FrameReportingView, context: Context) {
        nsView.onFrameChange = onFrameChange
        nsView.reportFrame()
    }
}

final class FrameReportingView: NSView {
    var onFrameChange: ((CGRect, NSScreen?) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        reportFrame()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        reportFrame()
    }

    override func setFrameOrigin(_ newOrigin: NSPoint) {
        super.setFrameOrigin(newOrigin)
        reportFrame()
    }

    func reportFrame() {
        guard let window else { return }

        // 1) bounds in the view's own coords
        let rectInView = self.bounds

        // 2) convert to window coords
        let rectInWindow = self.convert(rectInView, to: nil)

        // 3) convert to SCREEN coords (still Cocoa-style: origin bottom-left)
        let rectOnScreen = window.convertToScreen(rectInWindow)
        
        let screen = window.screen

        onFrameChange?(rectOnScreen, screen)
    }
}

