//
//  OverlayVerticalView.swift
//  MacRuler
//
//  Created by OpenAI Codex on 28/01/2026.
//

import SwiftUI

struct OverlayVerticalRulerView: View {
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
                        backingScale: overlayViewModel.backingScale)
                    .contentShape(Rectangle().inset(by: -8))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                overlayViewModel.selectedHandle = .top
                                overlayViewModel.topDividerY = value.location.y
                            }
                    )
                }

                if let bottomDividerY = overlayViewModel.bottomDividerY {
                    HorizontalDividerLine(
                        type: .bottom,
                        y: bottomDividerY * magnification,
                        width: geometry.size.width,
                        backingScale: overlayViewModel.backingScale)
                    .contentShape(Rectangle().inset(by: -8))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                overlayViewModel.selectedHandle = .bottom
                                let rawBounded = overlayViewModel.boundedDividerValue(value.location.y / magnification, maxValue: scaledHeight)
                                overlayViewModel.bottomDividerY = rawBounded
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
                    colors: [ Color.black.opacity(0.4),
                              Color.gray.opacity(0.9),
                              Color.white.opacity(0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onHover { value in
                isHovering = value
            }
            .scaleEffect(1.0)
            .opacity(1.0)
            .frame(width: width, height: lineWidth)
            .position(x: width / 2, y: y)
    }
}
