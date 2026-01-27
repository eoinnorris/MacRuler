//
//  OverlayHorizontalView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//

import SwiftUI

struct OverlayHorizontalView: View {
    @Binding var leftDividerX: CGFloat?
    @Binding var rightDividerX: CGFloat?
    let backingScale: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let leftDividerX {
                    DividerLine(
                        x: leftDividerX,
                        height: geometry.size.height,
                        backingScale: backingScale
                    )
                }

                if let rightDividerX {
                    DividerLine(
                        x: rightDividerX,
                        height: geometry.size.height,
                        backingScale: backingScale
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let clampedX = min(max(0, value.location.x), geometry.size.width)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            updateDividers(with: clampedX)
                        }
                    }
            )
        }
    }

    private func updateDividers(with x: CGFloat) {
        if leftDividerX == nil {
            leftDividerX = x
            return
        }

        if rightDividerX == nil {
            if let leftDividerX, x < leftDividerX {
                rightDividerX = leftDividerX
                leftDividerX = x
            } else {
                rightDividerX = x
            }
            return
        }

        guard let leftDividerX, let rightDividerX else { return }

        if x <= leftDividerX {
            self.leftDividerX = x
            return
        }

        if x >= rightDividerX {
            self.rightDividerX = x
            return
        }

        let leftDistance = abs(x - leftDividerX)
        let rightDistance = abs(rightDividerX - x)
        if leftDistance <= rightDistance {
            self.leftDividerX = x
        } else {
            self.rightDividerX = x
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
