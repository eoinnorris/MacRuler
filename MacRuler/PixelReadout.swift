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
            .modifier(PixelReadoutTextStyle())
    }
}

private struct PixelReadoutTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.body, design: .rounded))
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .stroke(
                                .white.opacity(0.25),
                                lineWidth: 0.5
                            )
                    }
            }
            .shadow(
                color: .black.opacity(0.15),
                radius: 6,
                y: 2
            )
    }
}
