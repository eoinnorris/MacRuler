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



fileprivate struct MeasurementScaleSettingsView: View {
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
fileprivate struct RulerSettingsView: View {
    @Binding var rulerSettingsViewModel: RulerSettingsViewModel

    private enum RulerSizeOption: String {
        case normal = "Normal"
        case large = "Large"

        var backgroundSize: RulerBackgroundSize {
            switch self {
            case .normal:
                .small
            case .large:
                .large
            }
        }
    }

    private var rulerSizeBinding: Binding<RulerSizeOption> {
        Binding(
            get: {
                rulerSettingsViewModel.horizontalRulerBackgroundSize == .large ? .large : .normal
            },
            set: { selectedSize in
                let backgroundSize = selectedSize.backgroundSize
                rulerSettingsViewModel.horizontalRulerBackgroundSize = backgroundSize
                rulerSettingsViewModel.verticalRulerBackgroundSize = backgroundSize
            }
        )
    }

    var body: some View {
        Section("Ruler") {
            Picker("Ruler Size", selection: rulerSizeBinding) {
                Text(RulerSizeOption.normal.rawValue).tag(RulerSizeOption.normal)
                Text(RulerSizeOption.large.rawValue).tag(RulerSizeOption.large)
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
            Toggle("Snap to major ruler ticks", isOn: $rulerSettingsViewModel.snapToMajorTicks)
            Stepper(
                value: $rulerSettingsViewModel.snapTolerancePoints,
                in: 1...20,
                step: 1
            ) {
                Text("Tolerance: \(Int(rulerSettingsViewModel.snapTolerancePoints)) pt")
            }

            Toggle(
                "Use fixed grid step",
                isOn: Binding(
                    get: { rulerSettingsViewModel.snapGridStepPoints != nil },
                    set: { rulerSettingsViewModel.snapGridStepPoints = $0 ? 10 : nil }
                )
            )

            if rulerSettingsViewModel.snapGridStepPoints != nil {
                Stepper(
                    value: snapGridStepBinding,
                    in: 1...200,
                    step: 1
                ) {
                    Text("Grid step: \(Int(snapGridStepBinding.wrappedValue)) pt")
                }
            }
        }
    }
}
