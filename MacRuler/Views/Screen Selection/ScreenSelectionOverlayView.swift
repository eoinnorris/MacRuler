//
//  ScreenSelectionOverlayView.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-01.
//

import SwiftUI
import AppKit

private enum SelectionInteractionState {
    case idle
    case dragging(initialRect: CGRect)
    case resizing(handle: SelectionResizeHandle, initialRect: CGRect)
}

private enum SelectionResizeHandle: CaseIterable {
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left

    var affectsLeftEdge: Bool {
        self == .topLeft || self == .left || self == .bottomLeft
    }

    var affectsRightEdge: Bool {
        self == .topRight || self == .right || self == .bottomRight
    }

    var affectsTopEdge: Bool {
        self == .topLeft || self == .top || self == .topRight
    }

    var affectsBottomEdge: Bool {
        self == .bottomLeft || self == .bottom || self == .bottomRight
    }

    func point(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft:
            CGPoint(x: rect.minX, y: rect.minY)
        case .top:
            CGPoint(x: rect.midX, y: rect.minY)
        case .topRight:
            CGPoint(x: rect.maxX, y: rect.minY)
        case .right:
            CGPoint(x: rect.maxX, y: rect.midY)
        case .bottomRight:
            CGPoint(x: rect.maxX, y: rect.maxY)
        case .bottom:
            CGPoint(x: rect.midX, y: rect.maxY)
        case .bottomLeft:
            CGPoint(x: rect.minX, y: rect.maxY)
        case .left:
            CGPoint(x: rect.minX, y: rect.midY)
        }
    }
}

private enum SelectionMetrics {
    static let minWidth: CGFloat = 120
    static let minHeight: CGFloat = 80
    static let handleSize: CGFloat = 10
}

struct ScreenSelectionOverlayView: View {
    var onSelection: (CGRect, NSScreen?) -> Void
    var onCancel: () -> Void

    @State private var draftStart: CGPoint?
    @State private var draftCurrent: CGPoint?
    @State private var selectionRect: CGRect?
    @State private var interactionState: SelectionInteractionState = .idle
    @State private var viewRectOnScreen: CGRect = .zero
    @State private var screen: NSScreen?

    private let backgroundGestureLogPrefix = "[ScreenSelectionOverlayView.backgroundGesture]"

    var body: some View {
        GeometryReader { geometry in
            let drawingRect = selectionRectFromPoints(draftStart, draftCurrent, in: geometry.size)
            let currentSelectionRect = selectionRect ?? drawingRect

            ZStack {
                greyBackdrop(selectionRect: currentSelectionRect)

                if let currentSelectionRect {
                    SelectionDancingAntsRectangle(rect: currentSelectionRect)
                        .allowsHitTesting(false)

                    if selectionRect != nil {
                        selectionBodyHitArea(rect: currentSelectionRect, in: geometry.size)
                        resizeHandles(rect: currentSelectionRect, in: geometry.size)
                    }
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
            .gesture(backgroundGesture(in: geometry.size))
            .onAppear {
                NSCursor.crosshair.push()
            }
            .onDisappear {
                NSCursor.pop()
            }
        }
    }

    private func backgroundGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard selectionRect == nil else { return }
                if draftStart == nil {
                    draftStart = value.startLocation
                    print("\(backgroundGestureLogPrefix) Started drafting selection at \(value.startLocation)")
                }
                draftCurrent = value.location
                if let liveRect = selectionRectFromPoints(draftStart, draftCurrent, in: size) {
                    print("\(backgroundGestureLogPrefix) Updated draft to rect: \(liveRect)")
                }
            }
            .onEnded { value in
                if let finalizedRect = selectionRect {
                    // Click outside commits the current selection.
                    if finalizedRect.contains(value.location) == false {
                        print("\(backgroundGestureLogPrefix) Click outside existing selection at \(value.location); submitting rect: \(finalizedRect)")
                        submitSelection(finalizedRect)
                    } else {
                        print("\(backgroundGestureLogPrefix) Click ended inside existing selection at \(value.location); ignoring")
                    }
                    return
                }

                guard let draftRect = selectionRectFromPoints(draftStart, draftCurrent, in: size) else {
                    print("\(backgroundGestureLogPrefix) No valid draft rect; cancelling selection")
                    resetDraft()
                    onCancel()
                    return
                }

                selectionRect = clampRectToBounds(draftRect, in: size)
                if let selectionRect {
                    print("\(backgroundGestureLogPrefix) Finalized selection rect: \(selectionRect)")
                }
                resetDraft()
                interactionState = .idle
            }
    }

    @ViewBuilder
    private func selectionBodyHitArea(rect: CGRect, in size: CGSize) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard let currentRect = selectionRect else { return }
                        if case .dragging(let initialRect) = interactionState {
                            let updatedRect = dragRect(initialRect: initialRect, translation: value.translation, in: size)
                            selectionRect = updatedRect
                        } else {
                            interactionState = .dragging(initialRect: currentRect)
                            let updatedRect = dragRect(initialRect: currentRect, translation: value.translation, in: size)
                            selectionRect = updatedRect
                        }
                    }
                    .onEnded { _ in
                        interactionState = .idle
                    }
            )
    }

    @ViewBuilder
    private func resizeHandles(rect: CGRect, in size: CGSize) -> some View {
        ForEach(SelectionResizeHandle.allCases, id: \.self) { handle in
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.black.opacity(0.8), lineWidth: 1))
                .frame(width: SelectionMetrics.handleSize, height: SelectionMetrics.handleSize)
                .position(handle.point(in: rect))
                .contentShape(Rectangle().inset(by: -6))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard let currentRect = selectionRect else { return }
                            if case .resizing(let activeHandle, let initialRect) = interactionState,
                               activeHandle == handle {
                                // Use the gesture translation from the original rect to avoid jitter.
                                selectionRect = resizeRect(
                                    initialRect: initialRect,
                                    handle: handle,
                                    translation: value.translation,
                                    in: size
                                )
                            } else {
                                interactionState = .resizing(handle: handle, initialRect: currentRect)
                                selectionRect = resizeRect(
                                    initialRect: currentRect,
                                    handle: handle,
                                    translation: value.translation,
                                    in: size
                                )
                            }
                        }
                        .onEnded { _ in
                            interactionState = .idle
                        }
                )
        }
    }

    private func selectionRectFromPoints(_ start: CGPoint?, _ current: CGPoint?, in size: CGSize) -> CGRect? {
        guard let start, let current else { return nil }
        let minX = min(start.x, current.x)
        let maxX = max(start.x, current.x)
        let minY = min(start.y, current.y)
        let maxY = max(start.y, current.y)
        let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        guard rect.width > 2, rect.height > 2 else { return nil }
        return clampRectToBounds(rect, in: size)
    }

    private func dragRect(initialRect: CGRect, translation: CGSize, in size: CGSize) -> CGRect {
        let bounds = CGRect(origin: .zero, size: size)

        // Clamp translated origin so the full rect remains inside the visible overlay bounds.
        let maxX = bounds.maxX - initialRect.width
        let maxY = bounds.maxY - initialRect.height
        let originX = min(max(initialRect.minX + translation.width, bounds.minX), maxX)
        let originY = min(max(initialRect.minY + translation.height, bounds.minY), maxY)

        return CGRect(origin: CGPoint(x: originX, y: originY), size: initialRect.size)
    }

    private func resizeRect(initialRect: CGRect, handle: SelectionResizeHandle, translation: CGSize, in size: CGSize) -> CGRect {
        let bounds = CGRect(origin: .zero, size: size)

        var left = initialRect.minX
        var right = initialRect.maxX
        var top = initialRect.minY
        var bottom = initialRect.maxY

        // Apply edge motion from the handle and then clamp to min size + bounds.
        if handle.affectsLeftEdge {
            left = min(max(initialRect.minX + translation.width, bounds.minX), initialRect.maxX - SelectionMetrics.minWidth)
        }
        if handle.affectsRightEdge {
            right = max(min(initialRect.maxX + translation.width, bounds.maxX), initialRect.minX + SelectionMetrics.minWidth)
        }
        if handle.affectsTopEdge {
            top = min(max(initialRect.minY + translation.height, bounds.minY), initialRect.maxY - SelectionMetrics.minHeight)
        }
        if handle.affectsBottomEdge {
            bottom = max(min(initialRect.maxY + translation.height, bounds.maxY), initialRect.minY + SelectionMetrics.minHeight)
        }

        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    private func clampRectToBounds(_ rect: CGRect, in size: CGSize) -> CGRect {
        let bounds = CGRect(origin: .zero, size: size)
        return rect.intersection(bounds)
    }

    private func resetDraft() {
        draftStart = nil
        draftCurrent = nil
    }

    private func submitSelection(_ selection: CGRect) {
        let screenRect = CGRect(
            x: viewRectOnScreen.minX + selection.minX,
            y: viewRectOnScreen.minY + selection.minY,
            width: selection.width,
            height: selection.height
        )
        onSelection(screenRect, screen)
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
