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
        ZStack {
            Color.clear
            RulerMagnifierView(magnifierSize: 180, viewModel: viewModel)
        }
        .padding(16)
    }
}
