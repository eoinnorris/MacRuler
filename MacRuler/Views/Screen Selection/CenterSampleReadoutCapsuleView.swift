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
    let auxiliaryReadouts: [String]
    let unitType: UnitTypes
    let measurementScale: Double
    let sourceScreenScale: Double

    var body: some View {
        VStack(alignment: .trailing) {
            ForEach(primaryReadouts, id: \.self) { readout in
                Text(readout)
            }
            Text("Center px: \(sampleReadout.coordinateLabel)")
            if let convertedCoordinates = sampleReadout.convertedCoordinateLabel(
                unitType: unitType,
                measurementScale: measurementScale,
                sourceScreenScale: sourceScreenScale
            ) {
                Text("Center \(unitType.unitSymbol): \(convertedCoordinates)")
            }
            Text("\(sampleReadout.rgbLabel) · \(sampleReadout.hexValue)")
            ForEach(secondaryReadouts, id: \.self) { readout in
                Text(readout)
            }
        }
        .font(.caption)
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.65))
        .clipShape(.capsule)
    }
}
