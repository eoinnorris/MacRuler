//
//  PixelReadout.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

struct PixelReadout: View  {
    let overlayViewModel: OverlayViewModel
    
    var body: some View {
        // ✅ Pixel width readout (top-left)
        VStack {
            HStack {
                Text("\(overlayViewModel.dividerDistancePixels) px")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.black.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.35), in: Capsule())
                Spacer()
            }
            Spacer()
        }
        .padding(10)
        .allowsHitTesting(false)
    }
}
