//
//  SelectionHintView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 08/02/2026.
//

import SwiftUI

struct SelectionHintView: View {
    let appDelegate: AppDelegate?

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            Text("Select a region of the screen to magnify")
                .font(.headline)
                .multilineTextAlignment(.center)

            GroupBox("Window") {
                VStack(spacing: 10) {
                    largeButton(title: "Select Window") {
                        appDelegate?.beginWindowSelection()
                    }
                    .keyboardShortcut(.defaultAction)

                    largeButton(title: "Screen Selection") {
                        appDelegate?.beginScreenSelection()
                    }
                }
                .padding(.top, 4)
            }

            GroupBox("Rulers") {
                VStack(spacing: 10) {
                    largeButton(title: "Show Horizontal Ruler") {
                        appDelegate?.setHorizontalRulerVisible(true)
                    }

                    largeButton(title: "Show Vertical Ruler") {
                        appDelegate?.setVerticalRulerVisible(true)
                    }
                }
                .padding(.top, 4)
            }

            Text("Choose a window or draw a screen area to begin magnifying.\nUse the ruler buttons any time to quickly reveal each ruler.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func largeButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
    }
}
