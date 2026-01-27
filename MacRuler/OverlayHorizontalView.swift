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
                }

                if let rightDividerX  = overlayViewModel.rightDividerX {
                    DividerLine(
                        x: rightDividerX,
                        height: geometry.size.height,
                        backingScale: overlayViewModel.backingScale
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
        max(1, 3 / backingScale)
    }

    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.75))
            .frame(width: lineWidth, height: height)
            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 0)
            .position(x: x, y: height / 2)
    }
}
