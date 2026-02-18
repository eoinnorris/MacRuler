//
//  MacRulerApp.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//

import SwiftUI
import AppKit
@preconcurrency import ScreenCaptureKit

@main
@MainActor
struct MacOSRulerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var rulerSettingsViewModel: RulerSettingsViewModel
    @State private var overlayViewModel: OverlayViewModel
    @State private var overlayVerticalViewModel: OverlayVerticalViewModel
    @State private var debugSettings: DebugSettingsModel

    init() {
        let dependencies = AppDependencies.live
        _rulerSettingsViewModel = State(initialValue: dependencies.rulerSettings)
        _overlayViewModel = State(initialValue: dependencies.overlay)
        _overlayVerticalViewModel = State(initialValue: dependencies.overlayVertical)
        _debugSettings = State(initialValue: dependencies.debugSettings)
    }
    
    var body: some Scene {
        // No default window; we’ll drive our own panels.
        Settings {
            SettingsView(rulerSettingsViewModel: $rulerSettingsViewModel)
        }
        .commands {
            CommandMenu("HRuler") {
                Button("Move Left") {
                    DividerKeyNotification.post(direction: .left, isDouble: false)
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command])
                Button("Move Right") {
                    DividerKeyNotification.post(direction: .right, isDouble: false)
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command])
                Divider()
                Button("Make Smaller") {
                    rulerSettingsViewModel.horizontalRulerBackgroundSize = .small
                }
                Button("Make Larger") {
                    rulerSettingsViewModel.horizontalRulerBackgroundSize = .large
                }
                Divider()
                Picker("Points", selection: $overlayViewModel.selectedPoints) {
                    ForEach(DividerStep.allCases) { step in
                        Text(step.displayName).tag(step)
                    }
                }
                Divider()
                Picker("Ruler Units", selection: $rulerSettingsViewModel.unitType) {
                    ForEach(UnitTypes.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                Divider()
                Toggle("Attach to vertical ruler", isOn: $rulerSettingsViewModel.attachBothRulers)
                Toggle("Lock horizontal ruler window", isOn: $rulerSettingsViewModel.horizontalRulerLocked)
                    .keyboardShortcut("l", modifiers: [.command])
            }
            CommandMenu("VRuler") {
                Button("Move Up") {
                    DividerKeyNotification.post(direction: .up, isDouble: false)
                }
                .keyboardShortcut(.upArrow, modifiers: [.command])
                Button("Move Down") {
                    DividerKeyNotification.post(direction: .down, isDouble: false)
                }
                .keyboardShortcut(.downArrow, modifiers: [.command])
                Divider()
                Button("Make Smaller") {
                    rulerSettingsViewModel.verticalRulerBackgroundSize = .small
                }
                Button("Make Larger") {
                    rulerSettingsViewModel.verticalRulerBackgroundSize = .large
                }
                Divider()
                Toggle("Attach to horizontal ruler", isOn: $rulerSettingsViewModel.attachBothRulers)
                Toggle("Lock vertical ruler window", isOn: $rulerSettingsViewModel.verticalRulerLocked)
                    .keyboardShortcut("v", modifiers: [.command])
            }
            CommandMenu("Screen picker") {
                Button("Increase Magnification") {
                    appDelegate.increaseSelectionMagnification()
                }
                .keyboardShortcut("=", modifiers: [.command])

                Button("Decrease Magnification") {
                    appDelegate.decreaseSelectionMagnification()
                }
                .keyboardShortcut("-", modifiers: [.command])

                Divider()

                Button("Select Window") {
                    appDelegate.beginWindowSelection()
                }
                Button("Screen selection") {
                    appDelegate.beginScreenSelection()
                }
            }
#if DEBUG
            CommandMenu("Debug") {
                Toggle("Show Window Background", isOn: $debugSettings.showWindowBackground)
            }
#endif
        }
    }
}
