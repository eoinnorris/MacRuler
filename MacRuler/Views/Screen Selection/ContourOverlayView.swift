//
//  ContourOverlayView.swift
//  MacRuler
//
//  Created by OpenAI on 2026-04-25.
//

import SwiftUI

struct ContourOverlayView: View {
    let normalizedContours: [CGPath]
    let contentOrigin: CGPoint
    let imageSize: CGSize
    let pathOffset: CGPoint

    var body: some View {
        Canvas { context, _ in
            guard !normalizedContours.isEmpty else { return }

            var transform = CGAffineTransform(translationX: contentOrigin.x, y: contentOrigin.y)
            transform = transform.concatenating(
                CGAffineTransform(
                    a: imageSize.width,
                    b: 0,
                    c: 0,
                    d: -imageSize.height,
                    tx: 0,
                    ty: imageSize.height
                )
            )

            for normalizedPath in normalizedContours {
                var pathTransform = transform

                if let mappedPath = normalizedPath.copy(using: &pathTransform) {
                    // Draw the contour path itself
                    context.stroke(
                        Path(mappedPath),
                        with: .color(.blue.opacity(0.95)),
                        style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter)
                    )

                    // Draw a bounding rectangle around the mapped path.
                    // Guard against degenerate paths (points/lines) with a minimum size threshold.
                    let bounds = mappedPath.boundingBoxOfPath
                    if !bounds.isNull && !bounds.isInfinite && bounds.width > 2 && bounds.height > 2 {
                        context.stroke(
                            Path(bounds),
                            with: .color(.orange.opacity(0.9)),
                            style: StrokeStyle(lineWidth: 1, lineCap: .square, lineJoin: .miter, dash: [4, 3])
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
