//
//  SelectionWindowToolbar.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-06.
//

import SwiftUI

struct SelectionWindowToolbar: View {
    @Bindable var session: SelectionSession
    @Bindable var rulerSettingsViewModel: RulerSettingsViewModel = .shared
    let snapshotAction: () -> Void
    let canTakeSnapshot: Bool

    var body: some View {
        HStack(spacing: 10) {
            magnificationControls

            Divider()
                .frame(height: 18)

            Button(action: snapshotAction) {
                Label("Snapshot", systemImage: "camera")
                    .labelStyle(.iconOnly)
            }
            .help("Save snapshot")
            .disabled(!canTakeSnapshot)

            Toggle(isOn: $session.showSelection) {
                Label("Show selection", systemImage: "rectangle.dashed.and.paperclip")
                    .labelStyle(.iconOnly)
            }
            .toggleStyle(.button)
            .help("Show selection for 2 seconds")

            Toggle(isOn: $rulerSettingsViewModel.showMagnifierPixelGrid) {
                Label("Pixel grid", systemImage: rulerSettingsViewModel.showMagnifierPixelGrid ? "square.grid.3x3.fill" : "square.grid.3x3")
                    .labelStyle(.iconOnly)
            }
            .toggleStyle(.button)
            .help("Show pixel grid")

            Toggle(isOn: $rulerSettingsViewModel.showMagnifierCrosshair) {
                Label("Crosshair", systemImage: rulerSettingsViewModel.showMagnifierCrosshair ? "plus.circle.fill" : "plus.circle")
                    .labelStyle(.iconOnly)
            }
            .toggleStyle(.button)
            .help("Show center crosshair")

            Toggle(isOn: $rulerSettingsViewModel.showMagnifierSecondaryCrosshair) {
                Label(
                    "Second crosshair",
                    systemImage: rulerSettingsViewModel.showMagnifierSecondaryCrosshair ? "plus.square.fill" : "plus.square"
                )
                .labelStyle(.iconOnly)
            }
            .toggleStyle(.button)
            .help("Show a second crosshair")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(.brandPrimary)
    }

    private var magnificationControls: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.magnifyingglass")
                .foregroundStyle(.secondary)
            Slider(
                value: $session.magnification,
                in: MagnificationViewModel.minimumMagnification...MagnificationViewModel.maximumMagnification,
                step: MagnificationViewModel.magnificationStep
            )
                .frame(width: 140)
            Text(MagnificationViewModel.formatLabel(session.magnification))
                .monospacedDigit()
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 54, alignment: .trailing)
        }
    }
}
