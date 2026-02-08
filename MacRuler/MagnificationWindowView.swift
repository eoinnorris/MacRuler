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
            if viewModel.rulerWindowFrame == .zero {
                SelectionHintView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                RulerMagnifierView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                HStack(spacing: 12) {
                    Slider(value: $viewModel.magnification, in: 1...5, step: 0.2)
                    Text(String(format: "%.0f%%", viewModel.magnification * 100))
                        .monospacedDigit()
                }
            }
        }
        .padding(16)
    }
}

private struct SelectionHintView: View {
    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)
            Text("Select a region of the screen to magnify")
                .font(.headline)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Button("Select Window") {
                    AppDelegate.shared?.beginWindowSelection()
                }
                .keyboardShortcut(.defaultAction)

                Button("Screen selection") {
                    AppDelegate.shared?.beginScreenSelection()
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
