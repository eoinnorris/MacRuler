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


        Section("Magnifier Crosshair") {
            Picker("Preset", selection: $rulerSettingsViewModel.magnifierCrosshairPreset) {
                ForEach(MagnifierCrosshairPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }

            Picker("Color", selection: $rulerSettingsViewModel.magnifierCrosshairColor) {
                ForEach(MagnifierCrosshairColor.allCases) { color in
                    Text(color.displayName).tag(color)
                }
            }

            Stepper(
                value: $rulerSettingsViewModel.magnifierCrosshairLineWidth,
                in: 0.5...5,
                step: 0.5
            ) {
                Text("Line width: \(rulerSettingsViewModel.magnifierCrosshairLineWidth, specifier: "%.1f")")
            }

            Toggle("Dual-stroke contrast", isOn: $rulerSettingsViewModel.magnifierCrosshairDualStrokeEnabled)
        }
        .onChange(of: rulerSettingsViewModel.magnifierCrosshairPreset) { previousPreset, preset in
            guard previousPreset != preset else { return }
            rulerSettingsViewModel.applyMagnifierCrosshairPreset(preset)
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
