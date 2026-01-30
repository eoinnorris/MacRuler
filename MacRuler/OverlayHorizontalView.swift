//
//  OverlayHorizontalView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//

import SwiftUI


struct OverlayHorizontalView: View {
    let overlayViewModel: OverlayViewModel
    @Bindable var magnificationViewModel: MagnificationViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if overlayViewModel.showDividerDance,
                   let leftDividerX = overlayViewModel.leftDividerX,
                   let rightDividerX = overlayViewModel.rightDividerX {
                    DancingAntsRectangle(
                        rect: DividerDanceMetrics.rect(
                            leftDividerX: leftDividerX,
                            rightDividerX: rightDividerX,
                            lineWidth: DividerDanceMetrics.baseLineWidth(backingScale: overlayViewModel.backingScale),
                            height: geometry.size.height
                        )
                    )
                    .background(
                        RulerFrameReader { rulerFrame, rulerWindowFrame, screen in
                            magnificationViewModel.dancingAntsFrame = rulerFrame
                            magnificationViewModel.rulerWindowFrame = rulerWindowFrame
                            magnificationViewModel.screen = screen
                        }
                    )
                    .allowsHitTesting(false)
                }

                if let leftDividerX  = overlayViewModel.leftDividerX {
                    DividerLine(
                        type: .left,
                        x: leftDividerX,
                        height: geometry.size.height,
                        backingScale: overlayViewModel.backingScale
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                overlayViewModel.leftDividerX = overlayViewModel.boundedDividerValue(value.location.x)
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
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                overlayViewModel.rightDividerX = overlayViewModel.boundedDividerValue(value.location.x)
                            }
                    )
                }
            }
            .contentShape(Rectangle())
            .onChange(of: overlayViewModel.showDividerDance) { _, newValue in
                if !newValue {
                    magnificationViewModel.dancingAntsFrame = .zero
                }
            }
            .onChange(of: overlayViewModel.leftDividerX) { _, _ in
                if overlayViewModel.leftDividerX == nil || overlayViewModel.rightDividerX == nil {
                    magnificationViewModel.dancingAntsFrame = .zero
                }
            }
            .onChange(of: overlayViewModel.rightDividerX) { _, _ in
                if overlayViewModel.leftDividerX == nil || overlayViewModel.rightDividerX == nil {
                    magnificationViewModel.dancingAntsFrame = .zero
                }
            }
        }
    }
}

private enum DividerDanceMetrics {
    static let padding: CGFloat = 4
    static let dashLength: CGFloat = 4
    static let dashSpacing: CGFloat = 4
    static let lineWidth: CGFloat = 1
    static let animationDuration: Double = 0.6

    static func baseLineWidth(backingScale: CGFloat) -> CGFloat {
        max(5, 7 / backingScale)
    }

    static func rect(leftDividerX: CGFloat, rightDividerX: CGFloat, lineWidth: CGFloat, height: CGFloat) -> CGRect {
        let minX = min(leftDividerX, rightDividerX) - (lineWidth / 2) - padding
        let maxX = max(leftDividerX, rightDividerX) + (lineWidth / 2) + padding
        let rectWidth = max(maxX - minX, 0)
        let rectHeight = max(height - (padding * 2), 0)
        return CGRect(x: minX, y: padding, width: rectWidth, height: rectHeight)
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

private struct DancingAntsRectangle: View {
    let rect: CGRect
    @State private var dashPhase: CGFloat = 0

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(
                    Color.black.opacity(0.1),
                    style: StrokeStyle(
                        lineWidth: DividerDanceMetrics.lineWidth,
                        dash: [DividerDanceMetrics.dashLength, DividerDanceMetrics.dashSpacing],
                        dashPhase: dashPhase
                    )
                )
            Rectangle()
                .stroke(
                    Color.black.opacity(0.1),
                    style: StrokeStyle(
                        lineWidth: DividerDanceMetrics.lineWidth,
                        dash: [DividerDanceMetrics.dashLength, DividerDanceMetrics.dashSpacing],
                        dashPhase: dashPhase + DividerDanceMetrics.dashLength
                    )
                )
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
//        .onAppear {
//            dashPhase = 0
//            withAnimation(.linear(duration: DividerDanceMetrics.animationDuration).repeatForever(autoreverses: false)) {
//                dashPhase = -(DividerDanceMetrics.dashLength + DividerDanceMetrics.dashSpacing)
//            }
//        }
    }
}
