//
//  OverlayHorizontalView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//

import SwiftUI


struct OverlayHorizontalView: View {
    let overlayViewModel:OverlayViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let leftDividerX  = overlayViewModel.leftDividerX {
                    DividerLine(
                        x: leftDividerX,
                        height: geometry.size.height,
                        backingScale: overlayViewModel.backingScale
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                overlayViewModel.leftDividerX = value.location.x
                            }
                    )
                }

                if let rightDividerX  = overlayViewModel.rightDividerX {
                    DividerLine(
                        x: rightDividerX,
                        height: geometry.size.height,
                        backingScale: overlayViewModel.backingScale
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                overlayViewModel.rightDividerX = value.location.x
                            }
                    )
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

    private var lineWidth: CGFloat {
        max(5, 7 / backingScale)
    }

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.9),
                        Color.black.opacity(0.4)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: lineWidth, height: height)
            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 0)
            .position(x: x, y: height / 2)
    }
}
