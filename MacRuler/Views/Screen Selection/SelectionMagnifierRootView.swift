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

    var body: some View {
        Group {
            if let session {
                ScreenSelectionMagnifierView(
                    session: session,
                    appDelegate: appDelegate,
                    controller: selectionCaptureObserver,
                    magnificationViewModel: magnificationViewModel,
                    horizontalOverlayViewModel: horizontalOverlayViewModel,
                    verticalOverlayViewModel:verticalOverlayViewModel
                )
            } else {
                SelectionHintView(appDelegate: appDelegate)
            }
        }
    }
}
