//
//  EdgeDetectionOverlayController.swift
//  MacRuler
//
//  Created by OpenAI on 2026-04-25.
//

import Observation
import CoreVideo
@preconcurrency import Vision

@Observable
@MainActor
final class EdgeDetectionOverlayController {
    var normalizedContours: [CGPath] = []
    var sourceFrame: CGRect = .zero
    var isEnabled = false

    @ObservationIgnored
    private let processingQueue = DispatchQueue(label: "MacRuler.EdgeDetection", qos: .userInitiated)

    @ObservationIgnored
    private var latestFrameToken: UInt64 = 0

    @ObservationIgnored
    private var pendingPixelBuffer: CVPixelBuffer?

    @ObservationIgnored
    private var latestPixelBuffer: CVPixelBuffer?

    @ObservationIgnored
    private var isDetectionInFlight = false

    @ObservationIgnored
    private var nextAllowedProcessingDate = Date.distantPast

    @ObservationIgnored
    private var deferredProcessingTask: Task<Void, Never>?

    private let targetDetectionFPS: TimeInterval = 12

    func connect(to streamCaptureObserver: StreamCaptureObserver) {
        streamCaptureObserver.setEdgeDetectionFrameHandler { [weak self] pixelBuffer in
            self?.receiveFrame(pixelBuffer)
        }
    }

    func disconnect(from streamCaptureObserver: StreamCaptureObserver) {
        streamCaptureObserver.setEdgeDetectionFrameHandler(nil)
    }

    func setEnabled(_ enabled: Bool, sourceFrame: CGRect) {
        isEnabled = enabled
        self.sourceFrame = sourceFrame

        guard enabled else {
            deferredProcessingTask?.cancel()
            deferredProcessingTask = nil
            pendingPixelBuffer = nil
            isDetectionInFlight = false
            normalizedContours = []
            return
        }

        pendingPixelBuffer = latestPixelBuffer
        scheduleProcessingIfNeeded()
    }

    func receiveFrame(_ pixelBuffer: CVPixelBuffer) {
        latestPixelBuffer = pixelBuffer
        guard isEnabled else { return }

        pendingPixelBuffer = pixelBuffer
        scheduleProcessingIfNeeded()
    }

    func updateOverlayFrame(_ frame: CGRect) {
        guard frame != .zero else { return }
        sourceFrame = frame
    }

    func clear() {
        isEnabled = false
        deferredProcessingTask?.cancel()
        deferredProcessingTask = nil
        latestFrameToken &+= 1
        pendingPixelBuffer = nil
        latestPixelBuffer = nil
        isDetectionInFlight = false
        normalizedContours = []
    }

    private func scheduleProcessingIfNeeded() {
        guard isEnabled, !isDetectionInFlight else { return }
        guard pendingPixelBuffer != nil else { return }

        let delay = max(0, nextAllowedProcessingDate.timeIntervalSinceNow)
        guard deferredProcessingTask == nil else { return }

        if delay == 0 {
            startProcessingPendingFrame()
            return
        }

        deferredProcessingTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.runDeferredProcessingIfNeeded()
        }
    }

    private func runDeferredProcessingIfNeeded() {
        deferredProcessingTask = nil
        startProcessingPendingFrame()
    }

    private func startProcessingPendingFrame() {
        guard isEnabled, !isDetectionInFlight else { return }
        guard let pixelBuffer = pendingPixelBuffer else { return }

        isDetectionInFlight = true
        pendingPixelBuffer = nil
        latestFrameToken &+= 1
        let frameToken = latestFrameToken
        let frameSnapshot = sourceFrame
        let minimumFrameInterval = 1.0 / targetDetectionFPS
        nextAllowedProcessingDate = Date().addingTimeInterval(minimumFrameInterval)

        processingQueue.async { [weak self] in
            guard let self else { return }
            let contourPaths = Self.detectContours(in: pixelBuffer)

            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.isEnabled, frameToken == self.latestFrameToken else {
                    self.isDetectionInFlight = false
                    self.scheduleProcessingIfNeeded()
                    return
                }

                self.sourceFrame = frameSnapshot
                self.normalizedContours = contourPaths
                self.isDetectionInFlight = false
                self.scheduleProcessingIfNeeded()
            }
        }
    }

    nonisolated
    private static func detectContours(in pixelBuffer: CVPixelBuffer) -> [CGPath] {

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        // Run two passes — one for dark-on-light, one for light-on-dark —
        // then merge, deduplicating paths that are near-identical in bounds.
        let paths = [true, false].flatMap { darkOnLight -> [CGPath] in
            let request = VNDetectContoursRequest()
            request.detectsDarkOnLight = darkOnLight
            request.contrastAdjustment = 2.0
            request.maximumImageDimension = max(width, height)

            // Dark on light pass — pivot below centre, background is bright
            request.contrastPivot = darkOnLight ? 0.2 : 0.7


            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .up
            )

            do {
                try handler.perform([request])
                guard let observation = request.results?.first else { return [] }
                // Only top-level contours — no children, so no internal boxes
                return observation.topLevelContours.map(\.normalizedPath)
            } catch {
                NSLog("Contour detection failed: \(error.localizedDescription)")
                return []
            }
        }

        // Deduplicate: if two paths from the two passes have bounding boxes
        // that are within 1% of each other, keep only one.
        return deduplicated(paths)
    }

    nonisolated
    private static func deduplicated(_ paths: [CGPath]) -> [CGPath] {
        var kept: [CGPath] = []
        for path in paths {
            let b = path.boundingBoxOfPath
            let isDuplicate = kept.contains { existing in
                let e = existing.boundingBoxOfPath
                guard e.width > 0, e.height > 0 else { return false }
                let dx = abs(b.midX - e.midX) / e.width
                let dy = abs(b.midY - e.midY) / e.height
                let dw = abs(b.width - e.width) / e.width
                let dh = abs(b.height - e.height) / e.height
                return dx < 0.01 && dy < 0.01 && dw < 0.01 && dh < 0.01
            }
            if !isDuplicate { kept.append(path) }
        }
        return kept
    }

    private static func allContours(from contours: [VNContour]) -> [VNContour] {
        contours.flatMap { contour in
            [contour] + allContours(from: contour.childContours)
        }
    }
}
