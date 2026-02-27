//
//  SettingsView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @Binding var rulerSettingsViewModel:RulerSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Form {
                UnitsSettingsView(rulerSettingsViewModel: $rulerSettingsViewModel)
                Divider()
                MeasurementScaleSettingsView(rulerSettingsViewModel: $rulerSettingsViewModel)
                Divider()
                RulerSettingsView(rulerSettingsViewModel: $rulerSettingsViewModel)
            }
        }
        .padding(20)
        .frame(width: 270)
        .tint(.brandPrimary)
    }
}
