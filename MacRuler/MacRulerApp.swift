//
//  MacRulerApp.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//

import SwiftUI
import AppKit
import Observation
@preconcurrency import ScreenCaptureKit

@main
struct MacOSRulerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var rulerSettingsViewModel = RulerSettingsViewModel.shared
    @State private var overlayViewModel = OverlayViewModel.shared
    @State private var overlayVerticalViewModel = OverlayVerticalViewModel.shared
    @State private var debugSettings = DebugSettingsModel.shared
    @State private var magnificationViewModel = MagnificationViewModel.shared
    @State private var selectionMagnificationViewModel = MagnificationViewModel.selection
    
    var body: some Scene {
        // No default window; we’ll drive our own panels.
        Settings {
            SettingsView(rulerSettingsViewModel: $rulerSettingsViewModel)
        }
        .commands {
            CommandMenu("HRuler") {
                Toggle("Select left handle", isOn: $overlayViewModel.leftHandleSelected)
                    .keyboardShortcut("1", modifiers: [.command])
                Toggle("Select right handle", isOn: $overlayViewModel.rightHandleSelected)
                    .keyboardShortcut("2", modifiers: [.command])
                Divider()
                
                Button("Move Left") {
                    DividerKeyNotification.post(direction: .left, isDouble: false)
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command])
                Button("Move Right") {
                    DividerKeyNotification.post(direction: .right, isDouble: false)
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command])
                Divider()
                Picker("Points", selection: $overlayViewModel.selectedPoints) {
                    ForEach(DividerStep.allCases) { step in
                        Text(step.displayName).tag(step)
                    }
                }
                Divider()
                Picker("Ruler Units", selection: $rulerSettingsViewModel.unitType) {
                    ForEach(UnitTyoes.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                Divider()
                Toggle("Attach to vertical ruler", isOn: $rulerSettingsViewModel.attachBothRulers)
            }
            CommandMenu("VRuler") {
                Toggle(VerticalDividerHandle.top.displayName, isOn: $overlayVerticalViewModel.topHandleSelected)
                    .keyboardShortcut("3", modifiers: [.command])
                Toggle(VerticalDividerHandle.bottom.displayName, isOn: $overlayVerticalViewModel.bottomHandleSelected)
                    .keyboardShortcut("4", modifiers: [.command])
                
                Divider()
                Button("Move Up") {
                    DividerKeyNotification.post(direction: .up, isDouble: false)
                }
                .keyboardShortcut(.upArrow, modifiers: [.command])
                Button("Move Down") {
                    DividerKeyNotification.post(direction: .down, isDouble: false)
                }
                .keyboardShortcut(.downArrow, modifiers: [.command])
                Divider()
                Toggle("Attach to horizontal ruler", isOn: $rulerSettingsViewModel.attachBothRulers)
            }
            CommandMenu("Magnification") {
                Toggle("Show Magnification", isOn: $magnificationViewModel.isMagnifierVisible)
                Toggle("Magnify Selection", isOn: $selectionMagnificationViewModel.isSelectionMagnifierVisible)
            }
            CommandMenu("Screen picker") {
                Button("Select Window") {
                    AppDelegate.shared?.beginWindowSelection()
                }
                Button("Screen selection") {
                    AppDelegate.shared?.beginScreenSelection()
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
