//
//  CenterSampleReadoutCapsuleView.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-23.
//

import SwiftUI

struct CenterSampleReadoutCapsule: View {
    let sampleReadout: CenterSampleReadout
    let auxiliaryReadouts: [String]

    var body: some View {
        VStack(alignment: .trailing) {
            ForEach(auxiliaryReadouts, id: \.self) { readout in
                Text(readout)
            }
            Text("Center: \(sampleReadout.coordinateLabel)")
            Text("\(sampleReadout.rgbLabel) · \(sampleReadout.hexValue)")
        }
        .font(.caption)
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.65))
        .clipShape(Capsule())
    }
}
