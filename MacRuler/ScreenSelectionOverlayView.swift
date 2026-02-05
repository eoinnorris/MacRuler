//
//  ScreenSelectionOverlayView.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-01.
//

import SwiftUI
import AppKit

struct ScreenSelectionOverlayView: View {
    var onSelection: (CGRect, NSScreen?) -> Void
    var onCancel: () -> Void

    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var viewRectOnScreen: CGRect = .zero
    @State private var screen: NSScreen?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                if let selectionRect = selectionRect(in: geometry.size) {
                    SelectionDancingAntsRectangle(rect: selectionRect)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .background(
                RulerFrameReader { viewRectOnScreen, _, screen in
                    self.viewRectOnScreen = viewRectOnScreen
                    self.screen = screen
                }
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragStart == nil {
                            dragStart = value.startLocation
                        }
                        dragCurrent = value.location
                    }
                    .onEnded { _ in
                        guard let selection = selectionRect(in: geometry.size) else {
                            resetDrag()
                            onCancel()
                            return
                        }
                        let screenRect = CGRect(
                            x: viewRectOnScreen.minX + selection.minX,
                            y: viewRectOnScreen.minY + selection.minY,
                            width: selection.width,
                            height: selection.height
                        )
                        resetDrag()
                        onSelection(screenRect, screen)
                    }
            )
            .onAppear {
                NSCursor.crosshair.push()
            }
            .onDisappear {
                NSCursor.pop()
            }
        }
    }

    private func selectionRect(in size: CGSize) -> CGRect? {
        guard let dragStart, let dragCurrent else { return nil }
        let minX = min(dragStart.x, dragCurrent.x)
        let maxX = max(dragStart.x, dragCurrent.x)
        let minY = min(dragStart.y, dragCurrent.y)
        let maxY = max(dragStart.y, dragCurrent.y)
        let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        guard rect.width > 2, rect.height > 2 else { return nil }
        return rect.intersection(CGRect(origin: .zero, size: size))
    }

    private func resetDrag() {
        dragStart = nil
        dragCurrent = nil
    }
}

private enum SelectionAntsMetrics {
    static let dashLength: CGFloat = 6
    static let dashSpacing: CGFloat = 4
    static let lineWidth: CGFloat = 1
    static let animationDuration: Double = 0.6
}

private struct SelectionDancingAntsRectangle: View {
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
