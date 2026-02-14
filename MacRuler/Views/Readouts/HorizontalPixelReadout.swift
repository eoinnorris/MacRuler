//
//  PixelReadout.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import AppKit
import SwiftUI


struct HorizontalPixelReadout: View {
    @Bindable var overlayViewModel: OverlayViewModel
    @Bindable var rulerSettingsViewModel:RulerSettingsViewModel
    @Bindable var magnificationViewModel: MagnificationViewModel


    var body: some View {
        let unitType = rulerSettingsViewModel.unitType
        let distancePoints = overlayViewModel.dividerX ?? 0
        let displayValue = unitType.formattedDistance(points: distancePoints, screenScale: overlayViewModel.backingScale)
        let magnificationLabel = MagnificationViewModel.formatLabel(magnificationViewModel.magnification)
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
            Text("\(displayValue) \(unitType.unitSymbol) • \(magnificationLabel)")
                .pixelReadoutTextStyle()
        }
    }
}
