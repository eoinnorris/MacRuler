//
//  OverlayVerticalView.swift
//  MacRuler
//
//  Created by OpenAI Codex on 28/01/2026.
//

import SwiftUI

struct OverlayVerticalView: View {
    let overlayViewModel: OverlayVerticalViewModel
    @Bindable var magnificationViewModel: MagnificationViewModel

    var body: some View {
        GeometryReader { geometry in
            let magnification = CGFloat(max(magnificationViewModel.magnification, 0.1))
            let scaledHeight = geometry.size.height / magnification

            ZStack {
                if let topDividerY = overlayViewModel.topDividerY {
                    HorizontalDividerLine(
                        type: .top,
                        y: topDividerY * magnification,
                        width: geometry.size.width,
                        backingScale: overlayViewModel.backingScale,
                        isSnapped: overlayViewModel.snappedHandle == .top,
                        pulseToken: overlayViewModel.snapPulseToken
                    )
                    .contentShape(Rectangle().inset(by: -8))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                overlayViewModel.selectedHandle = .top
                                let snapped = overlayViewModel.snappedValue(
                                    rawValue: value.location.y,
                                    axisLength: scaledHeight,
                                    magnification: magnification,
                                    unitType: RulerSettingsViewModel.shared.unitType
                                )
                                let rawBounded = overlayViewModel.boundedDividerValue(value.location.y / magnification, maxValue: scaledHeight)
                                overlayViewModel.setHandleSnappedState(.top, isSnapped: abs(snapped - rawBounded) > 0.001)
                                overlayViewModel.topDividerY = snapped
                            }
                    )
                }

                if let bottomDividerY = overlayViewModel.bottomDividerY {
                    HorizontalDividerLine(
                        type: .bottom,
                        y: bottomDividerY * magnification,
                        width: geometry.size.width,
                        backingScale: overlayViewModel.backingScale,
                        isSnapped: overlayViewModel.snappedHandle == .bottom,
                        pulseToken: overlayViewModel.snapPulseToken
                    )
                    .contentShape(Rectangle().inset(by: -8))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                overlayViewModel.selectedHandle = .bottom
                                let snapped = overlayViewModel.snappedValue(
                                    rawValue: value.location.y,
                                    axisLength: scaledHeight,
                                    magnification: magnification,
                                    unitType: RulerSettingsViewModel.shared.unitType
                                )
                                let rawBounded = overlayViewModel.boundedDividerValue(value.location.y / magnification, maxValue: scaledHeight)
                                overlayViewModel.setHandleSnappedState(.bottom, isSnapped: abs(snapped - rawBounded) > 0.001)
                                overlayViewModel.bottomDividerY = snapped
                            }
                    )
                }
            }
            .contentShape(Rectangle())
        }
    }
}

private enum HorizontalDividerLineType {
    case top
    case bottom
}

private struct HorizontalDividerLine: View {
    let type: HorizontalDividerLineType
    let y: CGFloat
    let width: CGFloat
    let backingScale: CGFloat
    let isSnapped: Bool
    let pulseToken: Int

    @State private var isHovering: Bool = false
    @State private var pulse: Bool = false

    private var lineWidth: CGFloat {
        if isHovering {
            return max(7, 10 / backingScale)
        } else {
            return max(5, 7 / backingScale)
        }
    }

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        isSnapped ? Color.blue.opacity(0.45) : Color.black.opacity(0.4),
                        isSnapped ? Color.cyan.opacity(0.9) : Color.gray.opacity(0.9),
                        isSnapped ? Color.white.opacity(0.8) : Color.white.opacity(0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onHover { value in
                isHovering = value
            }
            .scaleEffect(pulse ? 1.05 : 1.0)
            .opacity(pulse ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.16), value: pulse)
            .onChange(of: pulseToken) { _, _ in
                guard isSnapped else { return }
                pulse = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                    pulse = false
                }
            }
            .frame(width: width, height: lineWidth)
            .position(x: width / 2, y: y)
    }
}
