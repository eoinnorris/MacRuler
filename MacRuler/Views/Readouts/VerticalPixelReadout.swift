//
//  VerticalPixelReadout.swift
//  MacRuler
//
//  Created by Eoin Kortext on 08/02/2026.
//

import SwiftUI


struct VerticalPixelReadout: View {
    @Bindable var overlayViewModel: OverlayVerticalViewModel
    @Bindable var rulerSettingsViewModel: RulerSettingsViewModel
    @Bindable var magnificationViewModel: MagnificationViewModel

    var body: some View {
        let unitType = rulerSettingsViewModel.unitType
        let distancePoints = overlayViewModel.dividerY ?? 0
        let readoutComponents = ReadoutDisplayHelper.makeComponents(
            distancePoints: distancePoints,
            unitType: unitType,
            screenScale: overlayViewModel.backingScale,
            magnification: magnificationViewModel.magnification
        )
        Menu {
            Picker("Ruler Units", selection: $rulerSettingsViewModel.unitType) {
                ForEach(UnitTypes.allCases) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            Divider()
            SettingsLink {
                Text("Settings…")
            }
        } label: {
            Text(readoutComponents.text)
                .pixelReadoutTextStyle()
        }
    }
}
