//
//  PixelReadout.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI


struct PixelReadout: View {
    let overlayViewModel: OverlayViewModel

    var body: some View {
        Text("\(overlayViewModel.dividerDistancePixels) px")
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
