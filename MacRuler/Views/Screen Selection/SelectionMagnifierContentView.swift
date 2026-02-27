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
    @Bindable var horizontalOverlayViewModel: OverlayViewModel
    @Bindable var verticalOverlayViewModel: OverlayVerticalViewModel
    @Bindable var rulerSettingsViewModel: RulerSettingsViewModel = .shared

    var body: some View {
        ScreenSelectionMagnifierImage(
            session: session,
            controller: controller,
            horizontalOverlayViewModel: horizontalOverlayViewModel,
            verticalOverlayViewModel: verticalOverlayViewModel,
            rulerSettingsViewModel: rulerSettingsViewModel
        )
    }
}
