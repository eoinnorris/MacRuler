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
                        type: .left,
                        x: leftDividerX,
                        height: geometry.size.height,
                        backingScale: overlayViewModel.backingScale
                    )
                    .onHover { value in
                        overlayViewModel.leftDividerHover  = value
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                overlayViewModel.leftDividerX = value.location.x
                            }
                    )
                }

                if let rightDividerX  = overlayViewModel.rightDividerX {
                    DividerLine(
                        type: .right,
                        x: rightDividerX,
                        height: geometry.size.height,
                        backingScale: overlayViewModel.backingScale
                    )
                    .onHover { value in
                        overlayViewModel.rightDividerHover  = value
                    }
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

enum DividerLineType {
    case left
    case right
}

private struct DividerLine: View {
    let type:DividerLineType
    let x: CGFloat
    let height: CGFloat
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
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .onHover(perform: { value in
                isHovering =  value
            })
            .frame(width: lineWidth, height: height)
            .position(x: x, y: height / 2)
    }
}
