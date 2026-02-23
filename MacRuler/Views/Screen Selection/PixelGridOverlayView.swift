//
//  PixelGridOverlayView.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-23.
//

import SwiftUI

struct PixelGridOverlayView: View {
    let viewportSize: CGSize
    let contentOrigin: CGPoint
    let magnification: Double
    let screenScale: Double
    let showCrosshair: Bool
    let showSecondaryCrosshair: Bool
    let showPixelGrid: Bool

    private var pixelStep: CGFloat {
        CGFloat(max(magnification, 0.1) / max(screenScale, 0.1))
    }

    private var shouldShowGrid: Bool {
        showPixelGrid && magnification >= 4 && pixelStep >= 1
    }

    var body: some View {
        Canvas { context, size in
            if shouldShowGrid {
                var gridPath = Path()

                var x = alignedStart(originComponent: contentOrigin.x, step: pixelStep)
                while x <= size.width {
                    gridPath.move(to: CGPoint(x: x, y: 0))
                    gridPath.addLine(to: CGPoint(x: x, y: size.height))
                    x += pixelStep
                }

                var y = alignedStart(originComponent: contentOrigin.y, step: pixelStep)
                while y <= size.height {
                    gridPath.move(to: CGPoint(x: 0, y: y))
                    gridPath.addLine(to: CGPoint(x: size.width, y: y))
                    y += pixelStep
                }

                context.stroke(gridPath, with: .color(.white.opacity(0.2)), lineWidth: 0.5)
            }

            if showCrosshair {
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                drawCrosshair(at: center, in: &context, size: size)

                if showSecondaryCrosshair {
                    let offset = CGPoint(x: 24, y: 24)
                    let secondaryCenter = CGPoint(
                        x: min(max(center.x + offset.x, 0), size.width),
                        y: min(max(center.y + offset.y, 0), size.height)
                    )
                    drawCrosshair(at: secondaryCenter, in: &context, size: size)
                }
            }
        }
        .frame(width: viewportSize.width, height: viewportSize.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawCrosshair(at center: CGPoint, in context: inout GraphicsContext, size: CGSize) {
        var crosshairPath = Path()
        crosshairPath.move(to: CGPoint(x: center.x, y: 0))
        crosshairPath.addLine(to: CGPoint(x: center.x, y: size.height))
        crosshairPath.move(to: CGPoint(x: 0, y: center.y))
        crosshairPath.addLine(to: CGPoint(x: size.width, y: center.y))
        context.stroke(crosshairPath, with: .color(.white.opacity(0.85)), lineWidth: 1)
    }

    private func alignedStart(originComponent: CGFloat, step: CGFloat) -> CGFloat {
        let remainder = originComponent.truncatingRemainder(dividingBy: step)
        let normalized = remainder < 0 ? remainder + step : remainder
        return normalized
    }
}

private struct MagnifierContentFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private struct MagnifierFrameTrackingModifier: ViewModifier {
    let coordinateSpace: CoordinateSpace

    func body(content: Content) -> some View {
        content.background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: MagnifierContentFramePreferenceKey.self,
                    value: proxy.frame(in: coordinateSpace)
                )
            }
        }
    }
}

extension View {
    func trackFrame(in coordinateSpace: CoordinateSpace) -> some View {
        modifier(MagnifierFrameTrackingModifier(coordinateSpace: coordinateSpace))
    }

    func onFrameChange(_ action: @escaping (CGRect) -> Void) -> some View {
        onPreferenceChange(MagnifierContentFramePreferenceKey.self, perform: action)
    }
}
