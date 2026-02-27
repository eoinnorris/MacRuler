//
//  SettingsButton.swift
//  MacRuler
//

import SwiftUI
import AppKit

private struct SettingsButton: View {
    var body: some View {
        Button {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black.opacity(0.85))
                .padding(6)
                .background(.white.opacity(0.35), in: Circle())
        }
        .buttonStyle(.plain)
    }
}
