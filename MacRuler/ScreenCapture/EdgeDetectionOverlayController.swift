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
        let request = VNDetectContoursRequest()
        request.detectsDarkOnLight = true
        request.contrastAdjustment = 1.0
        request.maximumImageDimension = 512

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)

        do {
            try handler.perform([request])
            guard let contoursObservation = request.results?.first else {
                return []
            }
            return allContours(from: contoursObservation.topLevelContours).map(\.normalizedPath)
        } catch {
            NSLog("Contour detection failed: \(error.localizedDescription)")
            return []
        }
    }

    private static func allContours(from contours: [VNContour]) -> [VNContour] {
        contours.flatMap { contour in
            [contour] + allContours(from: contour.childContours)
        }
    }
}
