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

            HStack(spacing: 10) {
                Button("Select Window") {
                    appDelegate?.beginWindowSelection()
                }
                .keyboardShortcut(.defaultAction)

                Button("Screen selection") {
                    appDelegate?.beginScreenSelection()
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
