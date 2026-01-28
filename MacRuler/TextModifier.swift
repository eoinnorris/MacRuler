//
//  TextModifier.swift
//  MacRuler
//
//  Created by Eoin Kortext on 28/01/2026.
//

import SwiftUI

extension View {
    @ViewBuilder
    func pixelReadoutTextStyle() -> some View {
        self.modifier(PixelReadoutTextStyleModifier())
    }
}

private struct PixelReadoutTextStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
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
