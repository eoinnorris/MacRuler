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
    @State private var dragStartDividerX: CGFloat?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let magnification = CGFloat(max(magnificationViewModel.magnification, 0.1))
                let scaledWidth = geometry.size.width / magnification

                if let dividerX = overlayViewModel.dividerX {
                    let x = dividerX * magnification
                    let hitWidth: CGFloat = 16

                    // 1) Draw the line (no hit testing)
                    DividerLine(
                        x: x,
                        height: geometry.size.height,
                        backingScale: overlayViewModel.backingScale,
                        isHovering: isDividerHovering
                    )
                    .allowsHitTesting(false)

                    // 2) Hit target (this is what receives hover + drag)
                    Color.clear
                        .frame(width: hitWidth, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .offset(x: x - (geometry.size.width / 2))
                        .onHover { isHovering in
                            isDividerHovering = isHovering
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if dragStartDividerX == nil {
                                        dragStartDividerX = overlayViewModel.dividerX
                                    }

                                    let startXInView = (dragStartDividerX ?? overlayViewModel.dividerX ?? 0) * magnification
                                    let draggedXInView = startXInView + value.translation.width
                                    let rawBounded = overlayViewModel.boundedDividerValue(
                                        draggedXInView / magnification,
                                        maxValue: scaledWidth
                                    )
                                    overlayViewModel.dividerX = rawBounded
                                }
                                .onEnded { _ in
                                    dragStartDividerX = nil
                                }
                        )
                        .onDisappear {
                            isDividerHovering = false
                        }
                }

            }
        }
    }
}
