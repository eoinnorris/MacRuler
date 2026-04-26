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
final class EdgeDetectionOverlayController {
    var normalizedContours: [CGPath] = []
    var sourceFrame: CGRect = .zero
    var isEnabled = false

    @ObservationIgnored
    private let processingQueue = DispatchQueue(label: "MacRuler.EdgeDetection", qos: .userInitiated)

    @ObservationIgnored
    private var latestFrameToken: UInt64 = 0

    func setEnabled(_ enabled: Bool, sourceFrame: CGRect) {
        isEnabled = enabled
        self.sourceFrame = sourceFrame

        guard enabled else {
            normalizedContours = []
            return
        }
    }

    func processFrame(_ pixelBuffer: CVPixelBuffer, sourceFrame: CGRect) {
        guard isEnabled else { return }

        latestFrameToken &+= 1
        let frameToken = latestFrameToken
        self.sourceFrame = sourceFrame

        processingQueue.async { [weak self] in
            guard let self else { return }
            let contourPaths = Self.detectContours(in: pixelBuffer)

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                guard self.isEnabled, frameToken == self.latestFrameToken else { return }
                self.sourceFrame = sourceFrame
                self.normalizedContours = contourPaths
            }
        }
    }

    func updateOverlayFrame(_ frame: CGRect) {
        guard frame != .zero else { return }
        sourceFrame = frame
    }

    func clear() {
        isEnabled = false
        latestFrameToken &+= 1
        normalizedContours = []
    }

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
