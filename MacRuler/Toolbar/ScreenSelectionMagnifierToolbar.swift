//
//  ScreenSelectionMagnifierToolbar.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-27.
//

import SwiftUI

struct ScreenSelectionMagnifierToolbar: ToolbarContent {
    @Bindable var session: SelectionSession
    @Bindable var rulerSettingsViewModel: RulerSettingsViewModel = .shared
    let snapshotAction: () -> Void
    let canTakeSnapshot: Bool

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            magnificationControls

            Button(action: snapshotAction) {
                Label("Snapshot", systemImage: "camera")
            }
            .help("Save snapshot")
            .disabled(!canTakeSnapshot)

            Toggle(isOn: $session.showSelection) {
                Label("Show selection", systemImage: "rectangle.dashed.and.paperclip")
            }
            .toggleStyle(.button)
            .help("Show selection for 2 seconds")

            Toggle(isOn: $rulerSettingsViewModel.showMagnifierPixelGrid) {
                Label(
                    "Pixel grid",
                    systemImage: rulerSettingsViewModel.showMagnifierPixelGrid
                        ? "square.grid.3x3.fill"
                        : "square.grid.3x3"
                )
            }
            .toggleStyle(.button)
            .help("Show pixel grid")
        }
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
