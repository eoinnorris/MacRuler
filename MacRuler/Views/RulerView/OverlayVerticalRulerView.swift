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
    @GestureState private var isDividerDragging: Bool = false

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
                        setVerticalBackgroundLock(isLocked: isHovering, reason: .dividerHover)
                    }
                    .gesture(
                        DragGesture()
                            .updating($isDividerDragging) { _, state, _ in
                                state = true
                            }
                            .onChanged { value in
                                setVerticalBackgroundLock(isLocked: true, reason: .dividerDrag)
                                let rawBounded = overlayViewModel.boundedDividerValue(value.location.y / magnification, maxValue: scaledHeight)
                                overlayViewModel.dividerY = rawBounded
                            }
                            .onEnded { _ in
                                setVerticalBackgroundLock(isLocked: false, reason: .dividerDrag)
                            }
                    )
                    .onChange(of: isDividerDragging) { _, isDragging in
                        if !isDragging {
                            // Drag can terminate outside the divider path, so this guarantees unlock on cancellation/reset.
                            setVerticalBackgroundLock(isLocked: false, reason: .dividerDrag)
                        }
                    }
                    .onDisappear {
                        isDividerHovering = false
                        setVerticalBackgroundLock(isLocked: false, reason: .dividerHover)
                        setVerticalBackgroundLock(isLocked: false, reason: .dividerDrag)
                    }
                }
            }
            .contentShape(Rectangle())
        }
    }

    private func setVerticalBackgroundLock(isLocked: Bool, reason: AppDelegate.RulerBackgroundLockReason) {
        // Locking window-background dragging prevents the ruler window from moving while the divider is being edited.
        Task { @MainActor in
            AppDelegate.shared?.setVerticalRulerBackgroundLocked(isLocked, reason: reason)
        }
    }
}

private struct HorizontalDividerLine: View {
    let y: CGFloat
    let width: CGFloat
    let backingScale: CGFloat
    let isHovering: Bool

    private var lineWidth: CGFloat {
        if isHovering {
            return max(5, 7 / backingScale)
        } else {
            return max(1, 2 / backingScale)
        }
    }

    var body: some View {
        Rectangle()
            .fill(isHovering ?
                  AnyShapeStyle(
                    LinearGradient(
                        colors: [ Color.black.opacity(0.4),
                                  Color.gray.opacity(0.9),
                                  Color.white.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                  ) :
                  AnyShapeStyle(Color.gray.opacity(0.75))
            )
            .frame(width: width, height: lineWidth)
            .position(x: width / 2, y: y)
    }
}
