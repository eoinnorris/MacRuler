//
//  MeasurementScaleSettingsView.swift
//  MacRuler
//

import SwiftUI

struct MeasurementScaleSettingsView: View {
    @Binding var rulerSettingsViewModel: RulerSettingsViewModel

    private var manualScaleBinding: Binding<Double> {
        Binding(
            get: { rulerSettingsViewModel.manualMeasurementScale },
            set: { rulerSettingsViewModel.manualMeasurementScale = $0 }
        )
    }

    var body: some View {
        Section("Measurement Scale") {
            Picker("Scale Source", selection: $rulerSettingsViewModel.measurementScaleMode) {
                ForEach(MeasurementScaleMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            if rulerSettingsViewModel.measurementScaleMode == .manual {
                Stepper(value: manualScaleBinding, in: 0.5...4.0, step: 0.1) {
                    Text("Manual scale: \(manualScaleBinding.wrappedValue.formatted(.number.precision(.fractionLength(1))))x")
                }
            }

            Toggle("Show scale badge in readout", isOn: $rulerSettingsViewModel.showMeasurementScaleOverrideBadge)
        }
    }
}
