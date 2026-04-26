//
//  PixelGridOverlayView.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-23.
//

import SwiftUI
import CoreGraphics

struct PixelGridOverlayView: View {
    typealias CrosshairSelection = MagnifierCrosshairViewModel.CrosshairSelection

    let viewportSize: CGSize
    let contentOrigin: CGPoint
    let magnification: Double
    let screenScale: Double
    let showCrosshair: Bool
    let showSecondaryCrosshair: Bool
    let showPixelGrid: Bool
    let crosshairLineWidth: CGFloat
    let crosshairColor: Color
    let crosshairDualStrokeEnabled: Bool
    @Binding var primaryCrosshairOffset: CGSize
    @Binding var secondaryCrosshairOffset: CGSize
    @Binding var isPrimaryLocked: Bool
    @Binding var isSecondaryLocked: Bool
    @Binding var selectedCrosshair: CrosshairSelection
    @State private var isDraggingCrosshair = false


    private var pixelScaleModel: MagnifierPixelScaleModel {
        MagnifierPixelScaleModel(magnification: magnification, sourceScreenScale: screenScale)
    }

    private var pixelStep: CGFloat {
        pixelScaleModel.viewPointsPerSourcePixel
    }

    private var shouldShowGrid: Bool {
        showPixelGrid && magnification >= 4 && pixelStep >= 1
    }

    private var dragDistanceWidthLabelText: String {
        let widthInPoints = pixelScaleModel.sourcePointDistance(
            forViewDistance: abs(secondaryCrosshairOffset.width - primaryCrosshairOffset.width)
        )
        let roundedWidth = Int(widthInPoints.rounded())
        return "􀄾 \(roundedWidth)"
    }

    private var dragDistanceHeightLabelText: String {
        let heightInPoints = pixelScaleModel.sourcePointDistance(
            forViewDistance: abs(secondaryCrosshairOffset.height - primaryCrosshairOffset.height)
        )
        let roundedHeight = Int(heightInPoints.rounded())
        return "􀑹 \(roundedHeight)"
    }

    private var shouldShowDragDistanceLabel: Bool {
        guard isDraggingCrosshair, showCrosshair, showSecondaryCrosshair else {
            return false
        }

        return true
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
                        .contextMenu {
                            Button(isPrimaryLocked ? "Unlock Primary" : "Lock Primary") {
                                isPrimaryLocked.toggle()
                            }
                            Divider()
                            Button("Reset Selected") {
                                primaryCrosshairOffset = .zero
                            }
                            Button("Reset All") {
                                primaryCrosshairOffset = .zero
                                secondaryCrosshairOffset = MagnifierCrosshairViewModel.defaultSecondaryOffset
                            }
                        }

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
                            .contextMenu {
                                Button(isSecondaryLocked ? "Unlock Secondary" : "Lock Secondary") {
                                    isSecondaryLocked.toggle()
                                }
                                Divider()
                                Button("Reset Selected") {
                                    secondaryCrosshairOffset = MagnifierCrosshairViewModel.defaultSecondaryOffset
                                }
                                Button("Reset All") {
                                    primaryCrosshairOffset = .zero
                                    secondaryCrosshairOffset = MagnifierCrosshairViewModel.defaultSecondaryOffset
                                }
                            }
                    }

                    if shouldShowDragDistanceLabel {
                        dragDistanceLabels(in: proxy.size)
                    }
                }
            }
        }
        .onChange(of: magnification) { oldValue, newValue in
            guard oldValue != newValue else { return }
            guard newValue > oldValue else { return }
//            recenterCrosshairsAroundPrimary()
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
        if crosshairDualStrokeEnabled {
            context.stroke(
                crosshairPath,
                with: .color(.black.opacity(0.95)),
                lineWidth: crosshairLineWidth + 1.5
            )
        }

        context.stroke(
            crosshairPath,
            with: .color(crosshairColor.opacity(0.95)),
            lineWidth: crosshairLineWidth
        )
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

    private func secondaryCrosshairDragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !isSecondaryLocked else { return }
                isDraggingCrosshair = true
                selectedCrosshair = .secondary
                secondaryCrosshairOffset = crosshairOffset(for: value.location, in: size)
            }
            .onEnded { _ in
                guard !isSecondaryLocked else { return }
                isDraggingCrosshair = false
            }
    }

    private func primaryCrosshairDragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !isPrimaryLocked else { return }
                isDraggingCrosshair = true
                selectedCrosshair = .primary
                primaryCrosshairOffset = crosshairOffset(for: value.location, in: size)
            }
            .onEnded { _ in
                guard !isPrimaryLocked else { return }
                isDraggingCrosshair = false
            }
    }

    @ViewBuilder
    private func dragDistanceLabels(in size: CGSize) -> some View {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let primaryPoint = clampedPoint(
            for: CGPoint(
                x: center.x + primaryCrosshairOffset.width,
                y: center.y + primaryCrosshairOffset.height
            ),
            in: size
        )
        let secondaryPoint = clampedPoint(
            for: CGPoint(
                x: center.x + secondaryCrosshairOffset.width,
                y: center.y + secondaryCrosshairOffset.height
            ),
            in: size
        )
        let midpoint = CGPoint(
            x: (primaryPoint.x + secondaryPoint.x) / 2,
            y: (primaryPoint.y + secondaryPoint.y) / 2
        )
        let rightmostX = max(primaryPoint.x, secondaryPoint.x)
        let topmostY = min(primaryPoint.y, secondaryPoint.y)

        let widthLabelPoint = CGPoint(
            x: min(rightmostX + 36, size.width - 36),
            y: midpoint.y
        )

        let heightLabelPoint = CGPoint(
            x: midpoint.x,
            y: max(topmostY - 18, 16)
        )

        ZStack {
            dragDistanceLabel(text: dragDistanceHeightLabelText)
                .position(widthLabelPoint)

            dragDistanceLabel(text: dragDistanceWidthLabelText)
                .position(heightLabelPoint)
        }
    }

    private func dragDistanceLabel(text: String) -> some View {
        Text(text)
            .font(.body.monospacedDigit())
            .foregroundStyle(.brandPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
//            .background(.black.opacity(0.55), in: Capsule())
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
