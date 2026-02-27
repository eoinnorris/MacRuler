//
//  SelectionDancingAntsRectangle.swift
//  MacRuler
//

import SwiftUI

private enum SelectionAntsMetrics {
    static let dashLength: CGFloat = 6
    static let dashSpacing: CGFloat = 4
    static let lineWidth: CGFloat = 1
    static let animationDuration: Double = 0.6
}

struct SelectionDancingAntsRectangle: View {
    let rect: CGRect
    @State private var dashPhase: CGFloat = 0

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(
                    Color.black.opacity(0.8),
                    style: StrokeStyle(
                        lineWidth: SelectionAntsMetrics.lineWidth,
                        dash: [SelectionAntsMetrics.dashLength, SelectionAntsMetrics.dashSpacing],
                        dashPhase: dashPhase
                    )
                )
            Rectangle()
                .stroke(
                    Color.white.opacity(0.9),
                    style: StrokeStyle(
                        lineWidth: SelectionAntsMetrics.lineWidth,
                        dash: [SelectionAntsMetrics.dashLength, SelectionAntsMetrics.dashSpacing],
                        dashPhase: dashPhase + SelectionAntsMetrics.dashLength
                    )
                )
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        .onAppear {
            dashPhase = 0
            withAnimation(.linear(duration: SelectionAntsMetrics.animationDuration).repeatForever(autoreverses: false)) {
                dashPhase = -(SelectionAntsMetrics.dashLength + SelectionAntsMetrics.dashSpacing)
            }
        }
    }
}
