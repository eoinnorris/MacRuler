//
//  SelectionMagnifierRootView.swift
//  MacRuler
//

import SwiftUI

struct SelectionMagnifierRootView: View {
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
    }
}
