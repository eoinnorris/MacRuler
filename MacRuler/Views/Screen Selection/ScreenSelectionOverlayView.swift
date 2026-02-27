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
            let currentSelectionRect = selectionRect(in: geometry.size)

            ZStack {
                greyBackdrop(selectionRect: currentSelectionRect)

                if let currentSelectionRect {
                    SelectionDancingAntsRectangle(rect: currentSelectionRect)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .background(
                RulerFrameReader { viewRectOnScreen, _, screen in
                    Task { @MainActor in
                        self.viewRectOnScreen = viewRectOnScreen
                        self.screen = screen
                    }
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

    @ViewBuilder
    private func greyBackdrop(selectionRect: CGRect?) -> some View {
        if let selectionRect {
            GreyoutOutsideSelectionShape(selectionRect: selectionRect)
                .fill(Color.black.opacity(0.25), style: FillStyle(eoFill: true))
        } else {
            Color.black.opacity(0.25)
        }
    }
}

private struct GreyoutOutsideSelectionShape: Shape {
    let selectionRect: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addRect(selectionRect)
        return path
    }
}
