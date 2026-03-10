//
//  SelectionMagnifierRootView.swift
//  MacRuler
//

import SwiftUI

struct SelectionMagnifierRootView: View {
    @FocusState private var isFocused: Bool
    let session: SelectionSession?
    let appDelegate: AppDelegate?
    @Bindable var selectionCaptureObserver: StreamCaptureObserver
    @Bindable var horizontalOverlayViewModel: OverlayViewModel
    @Bindable var verticalOverlayViewModel: OverlayVerticalViewModel

    @Bindable var magnificationViewModel: MagnificationViewModel
    @Bindable var magnifierCrosshairViewModel: MagnifierCrosshairViewModel

    var body: some View {
        Group {
            if let session {
                ScreenSelectionMagnifierView(
                    session: session,
                    appDelegate: appDelegate,
                    magnificationViewModel: magnificationViewModel,
                    controller: selectionCaptureObserver,
                    horizontalOverlayViewModel: horizontalOverlayViewModel,
                    verticalOverlayViewModel:verticalOverlayViewModel,
                    magnifierCrosshairViewModel: magnifierCrosshairViewModel
                )
            } else {
                SelectionHintView(appDelegate: appDelegate)
            }
        }

        .focusable()
        .focused($isFocused)
        .onAppear {
            isFocused = true
        }
        .onKeyPress { keyPress in
            switch keyPress.key {
            case .leftArrow:
                 handleCrosshairNudge(x: -nudgeDistance(for: keyPress), y: 0)
            case .rightArrow:
                 handleCrosshairNudge(x: nudgeDistance(for: keyPress), y: 0)
            case .upArrow:
                 handleCrosshairNudge(x: 0, y: -nudgeDistance(for: keyPress))
            case .downArrow:
                 handleCrosshairNudge(x: 0, y: nudgeDistance(for: keyPress))
            default:
                 .handled
            }
        }
    }

    private func nudgeDistance(for keyPress: KeyPress) -> CGFloat {
        keyPress.modifiers.contains(.shift) ? 10 : 1
    }

    private func handleCrosshairNudge(x: CGFloat, y: CGFloat) -> KeyPress.Result {
        guard session != nil else { return .ignored }

        magnifierCrosshairViewModel.nudgeSelectedCrosshair(
            x: x,
            y: y,
            showSecondaryCrosshair: magnifierCrosshairViewModel.showSecondaryCrosshair
        )
        return .handled
    }
}
