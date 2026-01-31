//
//  VerticalRulerView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//

import SwiftUI

struct VerticalRulerView: View {
    @Bindable var settings: RulerSettingsViewModel
    @Bindable var debugSettings: DebugSettingsModel

    var body: some View {
        ZStack {
            RulerBackGround(rulerType: .vertical,
                            rulerSettingsViewModel: settings)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .background(
            debugSettings.showWindowBackground
            ? Color.black.opacity(0.15)
            : Color.clear
        )
        .padding(6)
    }
}
