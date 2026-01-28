//
//  PixelReadout.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import AppKit
import SwiftUI


struct PixelReadout: View {
    let overlayViewModel: OverlayViewModel
    @Bindable var rulerSettingsViewModel:RulerSettingsViewModel


    var body: some View {
        let unitType = rulerSettingsViewModel.unitType
        let distancePoints = CGFloat(overlayViewModel.dividerDistancePixels)
        let displayValue = unitType.formattedDistance(points: distancePoints, screenScale: overlayViewModel.backingScale)
        Menu {
            Picker("Ruler Units", selection: $rulerSettingsViewModel.unitType) {
                ForEach(UnitTyoes.allCases) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            Divider()
            SettingsLink {
                Text("Settings…")
            }
        } label: {
            Text("\(displayValue) \(unitType.unitSymbol)")
                .pixelReadoutTextStyle()
        }
    }
}
