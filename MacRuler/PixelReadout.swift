//
//  PixelReadout.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI


struct PixelReadout: View {
    let overlayViewModel: OverlayViewModel
    @Environment(RulerSettingsViewModel.self) private var rulerSettingsViewModel

    var body: some View {
        let unitType = rulerSettingsViewModel.unitType
        let distancePoints = CGFloat(overlayViewModel.dividerDistancePixels)
        let displayValue = unitType.formattedDistance(points: distancePoints, screenScale: overlayViewModel.backingScale)
        Text("\(displayValue) \(unitType.unitSymbol)")
            .pixelReadoutTextStyle()
    }
}

