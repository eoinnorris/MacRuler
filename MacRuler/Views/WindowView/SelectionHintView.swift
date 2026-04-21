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

            GroupBox("Selection") {
                VStack(spacing: 10) {
                    largeButton(title: "Screen Selection") {
                        appDelegate?.beginScreenSelection()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.top, 4)
            }

            GroupBox("Crosshair Tools") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Show crosshairs from the magnifier controls to place the horizontal and vertical guides on screen.")
                    Text("Drag the primary or secondary guide lines to position each reference exactly where you need it.")
                    Text("Reset guides at any time, then compare the two positions to read the delta measurement.")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }

            Text("Draw a screen area to begin magnifying.\nUse crosshair tools any time to place guides and compare spacing.")
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
