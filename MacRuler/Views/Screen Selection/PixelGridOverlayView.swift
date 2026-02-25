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
    @Binding var primaryCrosshairOffset: CGSize
    @Binding var secondaryCrosshairOffset: CGSize


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

            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            if showCrosshair {
                let primaryCenter = clampedPoint(
                    for: CGPoint(
                        x: center.x + primaryCrosshairOffset.width,
                        y: center.y + primaryCrosshairOffset.height
                    ),
                    in: size
                )
                drawCrosshair(at: primaryCenter, in: &context, size: size)

                if showSecondaryCrosshair {
                    let secondaryCenter = clampedPoint(
                        for: CGPoint(
                            x: center.x + secondaryCrosshairOffset.width,
                            y: center.y + secondaryCrosshairOffset.height
                        ),
                        in: size
                    )
                    drawCrosshair(at: secondaryCenter, in: &context, size: size)
                }
            }
        }
        .frame(width: viewportSize.width, height: viewportSize.height)
        .overlay {
            GeometryReader { proxy in
                let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

                if showCrosshair {
                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: 12, height: 12)
                        .position(clampedPoint(
                            for: CGPoint(
                                x: center.x + primaryCrosshairOffset.width,
                                y: center.y + primaryCrosshairOffset.height
                            ),
                            in: proxy.size
                        ))
                        .gesture(primaryCrosshairDragGesture(in: proxy.size))

                    if showSecondaryCrosshair {
                        Circle()
                            .fill(.white.opacity(0.7))
                            .frame(width: 12, height: 12)
                            .position(clampedPoint(
                                for: CGPoint(
                                    x: center.x + secondaryCrosshairOffset.width,
                                    y: center.y + secondaryCrosshairOffset.height
                                ),
                                in: proxy.size
                            ))
                            .gesture(secondaryCrosshairDragGesture(in: proxy.size))
                    }
                }
            }
        }
        .onChange(of: magnification) { oldValue, newValue in
            guard newValue > oldValue else { return }
            recenterCrosshairsAroundPrimary()
        }
        .accessibilityHidden(true)
    }

    private func recenterCrosshairsAroundPrimary() {
        let primaryOffset = primaryCrosshairOffset
        guard primaryOffset != .zero else { return }

        secondaryCrosshairOffset = CGSize(
            width: secondaryCrosshairOffset.width - primaryOffset.width,
            height: secondaryCrosshairOffset.height - primaryOffset.height
        )
        primaryCrosshairOffset = .zero
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

    private func clampedPoint(for point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), size.width),
            y: min(max(point.y, 0), size.height)
        )
    }

    private func crosshairOffset(for location: CGPoint, in size: CGSize) -> CGSize {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let clampedLocation = clampedPoint(for: location, in: size)
        return CGSize(
            width: clampedLocation.x - center.x,
            height: clampedLocation.y - center.y
        )
    }

    private func primaryCrosshairDragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                primaryCrosshairOffset = crosshairOffset(for: value.location, in: size)
            }
    }

    private func secondaryCrosshairDragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                secondaryCrosshairOffset = crosshairOffset(for: value.location, in: size)
            }
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
