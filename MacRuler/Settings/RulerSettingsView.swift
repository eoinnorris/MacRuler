//
//  RulerSettingsView.swift
//  MacRuler
//

import SwiftUI

struct RulerSettingsView: View {
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
