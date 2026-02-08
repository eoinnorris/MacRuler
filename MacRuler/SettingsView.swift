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
                AdvancedSettingsView(rulerSettingsViewModel: $rulerSettingsViewModel)
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
                ForEach(UnitTypes.allCases) { unit in
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
    @Binding var rulerSettingsViewModel: RulerSettingsViewModel

    private var snapGridStepBinding: Binding<CGFloat> {
        Binding(
            get: { rulerSettingsViewModel.snapGridStepPoints ?? 10 },
            set: { rulerSettingsViewModel.snapGridStepPoints = max($0, 1) }
        )
    }

    var body: some View {
        Section("Advanced") {
            Toggle("Enable Snapping", isOn: $rulerSettingsViewModel.snapEnabled)
            Toggle("Snap to major ruler ticks", isOn: $rulerSettingsViewModel.snapToMajorTicks)
                .disabled(!rulerSettingsViewModel.snapEnabled)
            Stepper(
                value: $rulerSettingsViewModel.snapTolerancePoints,
                in: 1...20,
                step: 1
            ) {
                Text("Tolerance: \(Int(rulerSettingsViewModel.snapTolerancePoints)) pt")
            }
            .disabled(!rulerSettingsViewModel.snapEnabled)

            Toggle(
                "Use fixed grid step",
                isOn: Binding(
                    get: { rulerSettingsViewModel.snapGridStepPoints != nil },
                    set: { rulerSettingsViewModel.snapGridStepPoints = $0 ? 10 : nil }
                )
            )
            .disabled(!rulerSettingsViewModel.snapEnabled)

            if rulerSettingsViewModel.snapGridStepPoints != nil {
                Stepper(
                    value: snapGridStepBinding,
                    in: 1...200,
                    step: 1
                ) {
                    Text("Grid step: \(Int(snapGridStepBinding.wrappedValue)) pt")
                }
                .disabled(!rulerSettingsViewModel.snapEnabled)
            }
        }
    }
}
