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
    @State private var isDividerHovering: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let magnification = CGFloat(max(magnificationViewModel.magnification, 0.1))
            let scaledHeight = geometry.size.height / magnification

            ZStack {
                if let dividerY = overlayViewModel.dividerY {
                    HorizontalDividerLine(
                        y: dividerY * magnification,
                        width: geometry.size.width,
                        backingScale: overlayViewModel.backingScale,
                        isHovering: isDividerHovering
                    )
                    .contentShape(Rectangle().inset(by: -8))
                    .onHover { isHovering in
                        isDividerHovering = isHovering
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let rawBounded = overlayViewModel.boundedDividerValue(value.location.y / magnification, maxValue: scaledHeight)
                                overlayViewModel.dividerY = rawBounded
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
