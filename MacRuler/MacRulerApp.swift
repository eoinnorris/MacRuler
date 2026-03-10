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
    @State private var magnifierCrosshairViewModel: MagnifierCrosshairViewModel
    @State private var debugSettings: DebugSettingsModel

    init() {
        let dependencies = AppDependencies.live
        _rulerSettingsViewModel = State(initialValue: dependencies.rulerSettings)
        _overlayViewModel = State(initialValue: dependencies.overlay)
        _overlayVerticalViewModel = State(initialValue: dependencies.overlayVertical)
        _magnifierCrosshairViewModel = State(initialValue: dependencies.magnifierCrosshair)
        _debugSettings = State(initialValue: dependencies.debugSettings)
    }
    
    var body: some Scene {
        // No default window; we’ll drive our own panels.
        Settings {
            SettingsView(rulerSettingsViewModel: $rulerSettingsViewModel)
        }
        .commands {
            CommandMenu("Screen picker") {
                Button("Toggle crosshair visibility") {
                    magnifierCrosshairViewModel.toggleCrosshairVisibility()
                }
                .keyboardShortcut("c", modifiers: [.command])

                Button("Toggle secondary crosshair visibility") {
                    magnifierCrosshairViewModel.toggleSecondaryCrosshairVisibility()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Button("Reset crosshair positions") {
                    magnifierCrosshairViewModel.resetAllOffsets()
                }
                .keyboardShortcut("0", modifiers: [.command])

                Divider()

                Button("Nudge secondary crosshair left by 1 px") {
                    magnifierCrosshairViewModel.nudgeSecondaryCrosshair(x: -1, y: 0)
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])

                Button("Nudge secondary crosshair right by 1 px") {
                    magnifierCrosshairViewModel.nudgeSecondaryCrosshair(x: 1, y: 0)
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])

                Button("Nudge secondary crosshair up by 1 px") {
                    magnifierCrosshairViewModel.nudgeSecondaryCrosshair(x: 0, y: -1)
                }
                .keyboardShortcut(.upArrow, modifiers: [.command, .option])

                Button("Nudge secondary crosshair down by 1 px") {
                    magnifierCrosshairViewModel.nudgeSecondaryCrosshair(x: 0, y: 1)
                }
                .keyboardShortcut(.downArrow, modifiers: [.command, .option])

                Button("Nudge secondary crosshair left by 10 px") {
                    magnifierCrosshairViewModel.nudgeSecondaryCrosshair(x: -10, y: 0)
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option, .shift])

                Button("Nudge secondary crosshair right by 10 px") {
                    magnifierCrosshairViewModel.nudgeSecondaryCrosshair(x: 10, y: 0)
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option, .shift])

                Button("Nudge secondary crosshair up by 10 px") {
                    magnifierCrosshairViewModel.nudgeSecondaryCrosshair(x: 0, y: -10)
                }
                .keyboardShortcut(.upArrow, modifiers: [.command, .option, .shift])

                Button("Nudge secondary crosshair down by 10 px") {
                    magnifierCrosshairViewModel.nudgeSecondaryCrosshair(x: 0, y: 10)
                }
                .keyboardShortcut(.downArrow, modifiers: [.command, .option, .shift])

                Divider()

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
