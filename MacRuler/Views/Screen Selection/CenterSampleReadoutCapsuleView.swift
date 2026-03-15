//
//  CenterSampleReadoutCapsuleView.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-23.
//

import SwiftUI

struct CenterSampleReadoutCapsule: View {
    let sampleReadout: CenterSampleReadout
    let primaryReadouts: [String]
    let secondaryReadouts: [String]
    let unitType: UnitTypes
    let measurementScale: Double
    let sourceScreenScale: Double
    let showCenterPixelCoordinates: Bool
    let showConvertedCenterCoordinates: Bool
    let showColorValues: Bool
    let showSecondaryReadouts: Bool
    @Binding var selectedColorOutputFormat: MagnifierColorOutputFormat
    @Binding var autoCopyColorOnPick: Bool
    let pickColorAction: (CenterSampleReadout) -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            ForEach(primaryReadouts, id: \.self) { readout in
                Text(readout)
            }

            if showCenterPixelCoordinates {
                Text("Center px: \(sampleReadout.coordinateLabel)")
            }

            if showConvertedCenterCoordinates,
               let convertedCoordinates = sampleReadout.convertedCoordinateLabel(
                unitType: unitType,
                measurementScale: measurementScale,
                sourceScreenScale: sourceScreenScale
               ) {
                Text("Center \(unitType.unitSymbol): \(convertedCoordinates)")
            }

            if showColorValues {
                Text("\(sampleReadout.rgbLabel) · \(sampleReadout.hexValue)")
            }

            if showSecondaryReadouts {
                ForEach(secondaryReadouts, id: \.self) { readout in
                    Text(readout)
                }
            }

            Divider().overlay(.white.opacity(0.35))

            HStack(spacing: 8) {
                Picker("Format", selection: $selectedColorOutputFormat) {
                    ForEach(MagnifierColorOutputFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)

                Toggle("Auto-copy", isOn: $autoCopyColorOnPick)
                    .toggleStyle(.switch)
                    .font(.caption)

                Button("Pick Color") {
                    pickColorAction(sampleReadout)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .font(.body)
        .foregroundStyle(.brandPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.65))
        .clipShape(.capsule)
    }
}
