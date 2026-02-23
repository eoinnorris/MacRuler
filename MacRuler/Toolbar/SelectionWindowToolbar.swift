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

    private var areCrosshairsEnabled: Bool {
        rulerSettingsViewModel.showMagnifierCrosshair && rulerSettingsViewModel.showMagnifierSecondaryCrosshair
    }

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

            if canTakeSnapshot {
                Button("Crosshairs", systemImage: "scope") {
                    let shouldEnableCrosshairs = !areCrosshairsEnabled
                    rulerSettingsViewModel.showMagnifierCrosshair = shouldEnableCrosshairs
                    rulerSettingsViewModel.showMagnifierSecondaryCrosshair = shouldEnableCrosshairs
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .background(areCrosshairsEnabled ? .gray.opacity(0.3) : .clear, in: .circle)
                .help("Toggle both crosshairs")
            }
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
