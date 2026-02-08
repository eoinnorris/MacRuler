//
//  PixelReadout.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import AppKit
import SwiftUI


struct PixelReadout: View {
    @Bindable var overlayViewModel: OverlayViewModel
    @Bindable var rulerSettingsViewModel:RulerSettingsViewModel
    @Bindable var magnificationViewModel: MagnificationViewModel


    var body: some View {
        let unitType = rulerSettingsViewModel.unitType
        let distancePoints = CGFloat(overlayViewModel.dividerDistancePixels)
        let displayValue = unitType.formattedDistance(points: distancePoints, screenScale: overlayViewModel.backingScale)
        let magnificationLabel = formatMagnificationLabel(magnificationViewModel.magnification)
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

struct VerticalPixelReadout: View {
    @Bindable var overlayViewModel: OverlayVerticalViewModel
    @Bindable var rulerSettingsViewModel: RulerSettingsViewModel
    @Bindable var magnificationViewModel: MagnificationViewModel

    var body: some View {
        let unitType = rulerSettingsViewModel.unitType
        let distancePoints = CGFloat(overlayViewModel.dividerDistancePixels)
        let displayValue = unitType.formattedDistance(points: distancePoints, screenScale: overlayViewModel.backingScale)
        let magnificationLabel = formatMagnificationLabel(magnificationViewModel.magnification)
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

private func formatMagnificationLabel(_ magnification: Double) -> String {
    let roundedValue = magnification.rounded()
    if abs(magnification - roundedValue) < 0.0001 {
        return "\(Int(roundedValue)) x"
    }

    return String(format: "%.1f x", magnification)
}
