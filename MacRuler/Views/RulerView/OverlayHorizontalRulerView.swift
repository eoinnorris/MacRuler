//
//  OverlayHorizontalView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//

import SwiftUI

struct OverlayHorizontalRulerView: View {
    let overlayViewModel: OverlayViewModel
    @Bindable var magnificationViewModel: MagnificationViewModel
    @State private var isDividerHovering: Bool = false
    @GestureState private var isDividerDragging: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let magnification = CGFloat(max(magnificationViewModel.magnification, 0.1))
                let scaledWidth = geometry.size.width / magnification

                if let dividerX = overlayViewModel.dividerX {
                    DividerLine(
                        x: dividerX * magnification,
                        height: geometry.size.height,
                        backingScale: overlayViewModel.backingScale,
                        isHovering: isDividerHovering
                    )
                    .contentShape(Rectangle().inset(by: -8))
                    .onHover { isHovering in
                        isDividerHovering = isHovering
                        setHorizontalBackgroundLock(isLocked: isHovering, reason: .dividerHover)
                    }
                    .gesture(
                        DragGesture()
                            .updating($isDividerDragging) { _, state, _ in
                                state = true
                            }
                            .onChanged { value in
                                setHorizontalBackgroundLock(isLocked: true, reason: .dividerDrag)
                                let rawBounded = overlayViewModel.boundedDividerValue(value.location.x / magnification, maxValue: scaledWidth)
                                overlayViewModel.dividerX = rawBounded
                            }
                            .onEnded { _ in
                                setHorizontalBackgroundLock(isLocked: false, reason: .dividerDrag)
                            }
                    )
                    .onChange(of: isDividerDragging) { _, isDragging in
                        if !isDragging {
                            // Drag can terminate outside the divider path, so this guarantees unlock on cancellation/reset.
                            setHorizontalBackgroundLock(isLocked: false, reason: .dividerDrag)
                        }
                    }
                    .onDisappear {
                        isDividerHovering = false
                        setHorizontalBackgroundLock(isLocked: false, reason: .dividerHover)
                        setHorizontalBackgroundLock(isLocked: false, reason: .dividerDrag)
                    }
                }
            }
            .contentShape(Rectangle())
        }
    }

    private func setHorizontalBackgroundLock(isLocked: Bool, reason: AppDelegate.RulerBackgroundLockReason) {
        // Locking window-background dragging prevents the ruler window from moving while the divider is being edited.
        Task { @MainActor in
            AppDelegate.shared?.setHorizontalRulerBackgroundLocked(isLocked, reason: reason)
        }
    }
}

private struct DividerLine: View {
    let x: CGFloat
    let height: CGFloat
    let backingScale: CGFloat
    let isHovering: Bool

    private var lineWidth: CGFloat {
        if isHovering {
            return max(5, 7 / backingScale)
        } else {
            return max(1, 3 / backingScale)
        }
    }

    var body: some View {
        Rectangle()
            .fill(isHovering ?
                  AnyShapeStyle(
                    LinearGradient(
                        colors: [Color.black.opacity(0.4),
                                 Color.gray.opacity(0.9),
                                 Color.white.opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                  ) :
                  AnyShapeStyle(Color.gray.opacity(0.75))
            )
            .frame(width: lineWidth, height: height)
            .position(x: x, y: height / 2)
    }
}
