//
//  MagnificationWindowView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 29/01/2026.
//

import SwiftUI

struct MagnificationWindowView: View {
    @Bindable var viewModel: MagnificationViewModel

    var body: some View {
        VStack(spacing: 12) {
            RulerMagnifierView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 12) {
                Slider(value: $viewModel.magnification, in: 1...5, step: 0.2)
                Text(String(format: "%.0f%%", viewModel.magnification * 100))
                    .monospacedDigit()
            }
        }
        .padding(16)
    }
}
