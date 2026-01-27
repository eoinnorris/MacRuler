//
//  SettingsView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(RulerSettingsViewModel.self) private var rulerSettingsViewModel

    var body: some View {
        Form {
            Section("Units") {
                Picker("Ruler Units", selection: $rulerSettingsViewModel.unitType) {
                    ForEach(UnitTyoes.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.radioGroup)
            }
        }
        .padding(20)
        .frame(minWidth: 280)
    }
}
