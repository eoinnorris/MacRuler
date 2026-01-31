//
//  OverlayVerticalView.swift
//  MacRuler
//
//  Created by OpenAI Codex on 28/01/2026.
//

import SwiftUI

struct OverlayVerticalView: View {
    let overlayViewModel: OverlayVerticalViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let topDividerY = overlayViewModel.topDividerY {
                    HorizontalDividerLine(
                        type: .top,
                        y: topDividerY,
                        width: geometry.size.width,
                        backingScale: overlayViewModel.backingScale
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                overlayViewModel.selectedHandle = .top
                                overlayViewModel.topDividerY = overlayViewModel.boundedDividerValue(value.location.y)
                            }
                    )
                }

                if let bottomDividerY = overlayViewModel.bottomDividerY {
                    HorizontalDividerLine(
                        type: .bottom,
                        y: bottomDividerY,
                        width: geometry.size.width,
                        backingScale: overlayViewModel.backingScale
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                overlayViewModel.selectedHandle = .bottom
                                overlayViewModel.bottomDividerY = overlayViewModel.boundedDividerValue(value.location.y)
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
                        Color.black.opacity(0.4),
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
            .frame(width: width, height: lineWidth)
            .position(x: width / 2, y: y)
    }
}
