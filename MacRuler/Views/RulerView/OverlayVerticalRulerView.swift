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
                if let dividerY = overlayViewModel.dividerY {
                    HorizontalDividerLine(
                        y: dividerY * magnification,
                        width: geometry.size.width,
                        backingScale: overlayViewModel.backingScale
                    )
                    .contentShape(Rectangle().inset(by: -8))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let rawBounded = overlayViewModel.boundedDividerValue(value.location.y / magnification, maxValue: scaledHeight)
                                overlayViewModel.dividerY = rawBounded
                            }
                    )
                }
            }
            .contentShape(Rectangle())
        }
    }
}

private struct HorizontalDividerLine: View {
    let y: CGFloat
    let width: CGFloat
    let backingScale: CGFloat

    @State private var isHovering: Bool = false

    private var lineWidth: CGFloat {
        if isHovering {
            return max(5, 7 / backingScale)
        } else {
            return max(3, 5 / backingScale)
        }
    }

    var body: some View {
        Rectangle()
            .fill(isHovering ?
                  AnyShapeStyle(
                    LinearGradient(
                        colors: [ Color.black.opacity(0.4),
                                  Color.gray.opacity(0.9),
                                  Color.white.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                  ) :
                  AnyShapeStyle(Color.gray.opacity(0.75))
            )
            .onHover { value in
                isHovering = value
            }
            .frame(width: width, height: lineWidth)
            .position(x: width / 2, y: y)
    }
}
