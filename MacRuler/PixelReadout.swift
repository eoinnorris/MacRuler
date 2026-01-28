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
            Menu("Go") {
                Picker("Handle", selection: $overlayViewModel.selectedHandle) {
                    ForEach(DividerHandle.allCases) { handle in
                        Text(handle.displayName).tag(handle)
                    }
                }
                Menu("Points") {
                    Picker("Points", selection: $overlayViewModel.selectedPoints) {
                        ForEach(DividerStep.allCases) { step in
                            Text(step.displayName).tag(step)
                        }
                    }
                }
                Divider()
                Button("Key Left") {
                    DividerKeyNotification.post(direction: .left, isDouble: false)
                }
                Button("Key Right") {
                    DividerKeyNotification.post(direction: .right, isDouble: false)
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
