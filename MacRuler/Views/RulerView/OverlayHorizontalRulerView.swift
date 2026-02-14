//
//  OverlayHorizontalView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//

import SwiftUI

struct OverlayHorizontalRulerView: View {
    let overlayViewModel: OverlayViewModel
    @Bindable var magnificationViewModel: MagnificationViewModel
    @State private var isDividerHovering: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let magnification = CGFloat(max(magnificationViewModel.magnification, 0.1))
                let scaledWidth = geometry.size.width / magnification

                if let dividerX = overlayViewModel.dividerX {
                    let x = dividerX * magnification
                    let hitWidth: CGFloat = 16  // tweak to taste

                    // 1) Draw the line (no hit testing)
                    DividerLine(
                        x: x,
                        height: geometry.size.height,
                        backingScale: overlayViewModel.backingScale,
                        isHovering: isDividerHovering
                    )
                    .allowsHitTesting(false)

                    // 2) Hit target (this is what receives hover + drag)
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: hitWidth, height: geometry.size.height)
                        .position(x: x, y: geometry.size.height / 2)
                        .contentShape(Rectangle())
                        .onHover { isHovering in
                            isDividerHovering = isHovering
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let rawBounded = overlayViewModel.boundedDividerValue(
                                        value.location.x / magnification,
                                        maxValue: scaledWidth
                                    )
                                    overlayViewModel.dividerX = rawBounded
                                }
                        )
                        .onDisappear {
                            isDividerHovering = false
                        }
                }

            }
            .contentShape(Rectangle())
        }
    }
}

private struct DividerLine: View {
    let x: CGFloat
    let height: CGFloat
    let backingScale: CGFloat
    let isHovering: Bool

    private var lineWidth: CGFloat {
        if isHovering {
            return max(5, 7 / backingScale)
        } else {
            return max(1, 3 / backingScale)
        }
    }

    var body: some View {
        Rectangle()
            .fill(isHovering ?
                  AnyShapeStyle(
                    LinearGradient(
                        colors: [Color.black.opacity(0.4),
                                 Color.gray.opacity(0.9),
                                 Color.white.opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                  ) :
                  AnyShapeStyle(Color.gray.opacity(0.75))
            )
            .frame(width: lineWidth, height: height)
            .position(x: x, y: height / 2)
    }
}
