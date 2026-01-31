//
//  VerticalRulerView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//

import SwiftUI

struct VerticalRulerView: View {
    @Bindable var overlayViewModel: OverlayVerticalViewModel
    @Bindable var settings: RulerSettingsViewModel
    @Bindable var debugSettings: DebugSettingsModel

    var body: some View {
        ZStack {
            RulerBackGround(rulerType: .vertical,
                            rulerSettingsViewModel: settings)
            .frame(width: 44.0)
            OverlayVerticalView(overlayViewModel: overlayViewModel)
            WindowScaleReader(
                backingScale: $overlayViewModel.backingScale,
                windowFrame: $overlayViewModel.windowFrame
            )
            .frame(width: 0, height: 0)
        }
        .onTapGesture { location in
            withAnimation(.easeInOut(duration: 0.2)) {
                overlayViewModel.updateDividers(with: location.y)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .background(
            debugSettings.showWindowBackground
            ? Color.black.opacity(0.15)
            : Color.clear
        )
        .padding(6)
    }
}
