//
//  SelectionMagnifierContentView.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-06.
//

import SwiftUI

struct SelectionMagnifierContentView: View {
    @Bindable var session: SelectionSession
    @Bindable var controller: StreamCaptureObserver
    @Bindable var edgeDetectionOverlayController: EdgeDetectionOverlayController
    @Bindable var horizontalOverlayViewModel: OverlayViewModel
    @Bindable var verticalOverlayViewModel: OverlayVerticalViewModel
    @Bindable var magnifierCrosshairViewModel: MagnifierCrosshairViewModel

    var body: some View {
        ScreenSelectionMagnifierImage(
            session: session,
            controller: controller,
            edgeDetectionOverlayController: edgeDetectionOverlayController,
            horizontalOverlayViewModel: horizontalOverlayViewModel,
            verticalOverlayViewModel: verticalOverlayViewModel,
            crosshairViewModel: magnifierCrosshairViewModel
        )
    }
}
