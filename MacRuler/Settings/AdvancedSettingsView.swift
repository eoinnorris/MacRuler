//
//  AdvancedSettingsView.swift
//  MacRuler
//

import SwiftUI

struct AdvancedSettingsView: View {
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


        Section("Magnifier Readout") {
            Toggle("Show center pixel coordinates", isOn: $rulerSettingsViewModel.showMagnifierReadoutCenterPixel)
            Toggle(
                "Show converted center coordinates",
                isOn: $rulerSettingsViewModel.showMagnifierReadoutConvertedCoordinates
            )
            Toggle("Show center color values", isOn: $rulerSettingsViewModel.showMagnifierReadoutColor)
            Toggle("Show ruler readouts (H/V)", isOn: $rulerSettingsViewModel.showMagnifierReadoutSecondaryReadouts)
        }

    }
}