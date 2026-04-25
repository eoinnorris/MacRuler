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
                    context.stroke(
                        Path(mappedPath),
                        with: .color(.pink.opacity(0.95)),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
