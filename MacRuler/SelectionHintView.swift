//
//  SelectionHintView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 08/02/2026.
//

import SwiftUI

struct SelectionHintView: View {
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
