//
//  UnitsSettingsView.swift
//  MacRuler
//

import SwiftUI

struct UnitsSettingsView: View {
    @Binding var rulerSettingsViewModel: RulerSettingsViewModel

    var body: some View {
        Section("Units") {
            Picker("Ruler Units", selection: $rulerSettingsViewModel.unitType) {
                ForEach(UnitTypes.allCases) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            .pickerStyle(.radioGroup)
            .padding(.top)
        }
    }
}
