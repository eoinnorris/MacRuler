//
//  SettingsView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @Binding var rulerSettingsViewModel:RulerSettingsViewModel
//    @Environment(RulerSettingsViewModel.self) private var rulerSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Form {
                UnitsSettingsView(rulerSettingsViewModel: $rulerSettingsViewModel)
                Divider()
                RulerSettingsView()
                Divider()
                AdvancedSettingsView()
            }
        }
        .padding(20)
        .frame(width: 270)
    }
}

fileprivate struct UnitsSettingsView: View {
    @Binding var rulerSettingsViewModel: RulerSettingsViewModel

    var body: some View {
        Section("Units") {
            Picker("Ruler Units", selection: $rulerSettingsViewModel.unitType) {
                ForEach(UnitTyoes.allCases) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            .pickerStyle(.radioGroup)
            .padding(.top)
        }
    }
}

fileprivate struct RulerSettingsView: View {
    @State private var rulerSize = "Normal"

    var body: some View {
        Section("Ruler") {
            Picker("Ruler Size", selection: $rulerSize) {
                Text("Normal").tag("Normal")
                Text("Large").tag("Large")
            }
            .pickerStyle(.radioGroup)
            .padding(.top)

        }
    }
}

fileprivate struct AdvancedSettingsView: View {
    var body: some View {
        Section("Advanced") {
            Text("This is the Advanced section.")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)
        }
    }
}
