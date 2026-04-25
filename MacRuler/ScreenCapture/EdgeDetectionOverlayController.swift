//
//  EdgeDetectionOverlayController.swift
//  MacRuler
//
//  Created by OpenAI on 2026-04-25.
//

import AppKit
import CoreVideo
import QuartzCore
@preconcurrency import Vision

final class EdgeDetectionOverlayController {
    private let overlayPanel = ContourOverlayPanel()
    private let contourView = ContourOverlayView()
    private let processingQueue = DispatchQueue(label: "MacRuler.EdgeDetection", qos: .userInitiated)

    private var isEnabled = false
    private var latestFrameToken: UInt64 = 0
    private var lastSourceFrame: CGRect = .zero

    init() {
        overlayPanel.contentView = contourView
    }

    func setEnabled(_ enabled: Bool, sourceFrame: CGRect) {
        isEnabled = enabled
        lastSourceFrame = sourceFrame

        guard enabled else {
            contourView.clearContours()
            overlayPanel.orderOut(nil)
            return
        }

        updateOverlayFrame(sourceFrame)
        overlayPanel.orderFrontRegardless()
    }

    func processFrame(_ pixelBuffer: CVPixelBuffer, sourceFrame: CGRect) {
        guard isEnabled else { return }

        latestFrameToken &+= 1
        let frameToken = latestFrameToken
        lastSourceFrame = sourceFrame

        processingQueue.async { [weak self] in
            guard let self else { return }
            let contourPaths = Self.detectContours(in: pixelBuffer)

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                guard self.isEnabled, frameToken == self.latestFrameToken else { return }
                self.updateOverlayFrame(sourceFrame)
                self.contourView.updateContours(contourPaths)
                self.overlayPanel.orderFrontRegardless()
            }
        }
    }

    func updateOverlayFrame(_ frame: CGRect) {
        guard frame != .zero else { return }
        lastSourceFrame = frame
        overlayPanel.setFrame(frame, display: true)
        contourView.frame = NSRect(origin: .zero, size: frame.size)
        contourView.needsLayout = true
    }

    func clear() {
        isEnabled = false
        latestFrameToken &+= 1
        contourView.clearContours()
        overlayPanel.orderOut(nil)
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

private final class ContourOverlayPanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class ContourOverlayView: NSView {
    private let contourLayer = CAShapeLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor.clear.cgColor

        contourLayer.fillColor = NSColor.clear.cgColor
        contourLayer.strokeColor = NSColor.systemPink.withAlphaComponent(0.95).cgColor
        contourLayer.lineWidth = 2.0
        contourLayer.lineJoin = .round
        contourLayer.lineCap = .round

        layer?.addSublayer(contourLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        layer?.frame = bounds
        contourLayer.frame = bounds
    }

    func updateContours(_ normalizedPaths: [CGPath]) {
        let mutablePath = CGMutablePath()
        let transform = CGAffineTransform(
            a: bounds.width,
            b: 0,
            c: 0,
            d: -bounds.height,
            tx: 0,
            ty: bounds.height
        )

        for normalizedPath in normalizedPaths {
            if let mapped = normalizedPath.copy(using: &transform) {
                mutablePath.addPath(mapped)
            }
        }

        contourLayer.path = mutablePath
    }

    func clearContours() {
        contourLayer.path = nil
    }
}
