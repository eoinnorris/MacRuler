//
//  MacRulerApp.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//

import SwiftUI
import AppKit
import Observation

@main
struct MacOSRulerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var rulerSettingsViewModel = RulerSettingsViewModel.shared
    @State private var overlayViewModel = OverlayViewModel.shared
    @State private var debugSettings = DebugSettingsModel.shared
    @State private var magnificationViewModel = MagnificationViewModel.shared
    
    var body: some Scene {
        // No default window; we’ll drive our own panels.
        Settings {
            SettingsView(rulerSettingsViewModel: $rulerSettingsViewModel)
        }
        .commands {
            CommandMenu("Ruler") {
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
            }
            CommandMenu("Magnification") {
                Toggle("Show Magnification", isOn: $magnificationViewModel.isMagnifierVisible)
                Toggle("Show Divider Dance", isOn: $overlayViewModel.showDividerDance)
            }
#if DEBUG
            CommandMenu("Debug") {
                Toggle("Show Window Background", isOn: $debugSettings.showWindowBackground)
            }
#endif
        }
    }
}


final class AppDelegate: NSObject, NSApplicationDelegate {

    private var horizontalController: NSWindowController?
    private var verticalController: NSWindowController?
    private var magnifierController: NSWindowController?
    private let horizontalResizeDelegate = HorizontalRulerWindowDelegate(fixedHeight: Constants.horizontalHeight)
    private let magnificationViewModel = MagnificationViewModel.shared
    private lazy var magnifierWindowDelegate = MagnifierWindowDelegate(viewModel: magnificationViewModel)
    private var magnificationObservationTask: Task<Void, Never>?

    
    func makeHorizontalRulerView() -> some View {
        HorizontalRulerView(overlayViewModel: OverlayViewModel.shared,
                            settings: RulerSettingsViewModel.shared,
                            debugSettings: DebugSettingsModel.shared,
                            magnificationViewModel: MagnificationViewModel.shared)
            .frame(height: Constants.horizontalHeight)
            .fixedSize(horizontal: false, vertical: true)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Optional: make it behave like a menu-bar-ish utility app (no Dock icon)
        // Comment this out if you *do* want a normal app presence.
//        NSApp.setActivationPolicy(.accessory)

        guard let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame  // avoids menu bar + dock

        // Horizontal panel (top third area)
        let defaultWidth = min(450, vf.width - 40)
        let hWidth = storedHorizontalWidth(
            defaultWidth: defaultWidth,
            screenWidth: vf.width
        )
        let hSize = NSSize(width: hWidth, height: Constants.horizontalHeight)
        let topThirdMinY = vf.minY + (vf.height * (2.0 / 3.0))
        let topThirdHeight = vf.height / 3.0
        let hOrigin = NSPoint(
            x: vf.minX + (vf.width - hSize.width) / 2,
            y: topThirdMinY + (topThirdHeight - hSize.height) / 2
        )
        let hPanel = makePanel(
            frame: NSRect(origin: hOrigin, size: hSize),
            rootView: makeHorizontalRulerView()
        )
        horizontalController = NSWindowController(window: hPanel)
        horizontalController?.showWindow(nil)

        
        hPanel.delegate = horizontalResizeDelegate
        hPanel.maxSize = NSSize(width: 1000, height: Constants.horizontalHeight)
        hPanel.contentMaxSize = NSSize(width: 1000, height: Constants.horizontalHeight)

        // Vertical panel (left area)
        let vSize = NSSize(width: Constants.verticalWidth , height: min(700, vf.height - 40))
        let vOrigin = NSPoint(
            x: vf.minX + 10,
            y: vf.minY + (vf.height - vSize.height) / 2
        )
        let vPanel = makePanel(
            frame: NSRect(origin: vOrigin, size: vSize),
            rootView: VerticalRulerView(debugSettings: DebugSettingsModel.shared)
        )
        verticalController = NSWindowController(window: vPanel)
        verticalController?.showWindow(nil)

        startMagnificationObservation()
        syncMagnifierVisibility()
    }

    private func makePanel<Content: View>(
        frame: NSRect,
        rootView: Content
    ) -> NSPanel {
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [
                .titled,
                .fullSizeContentView,
                .nonactivatingPanel,
                .resizable              // ✅ allow resize
            ],
            backing: .buffered,
            defer: false
        )
        

        // Always on top
        panel.level = .floating

        // Show on all Spaces, and alongside fullscreen apps
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Utility feel
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true

        // If you want a “HUD-ish” look
        panel.isOpaque = false
        panel.backgroundColor = .clear

        panel.contentView = NSHostingView(rootView: rootView)
        

        // Optional: remove standard buttons (close/min/zoom)
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        return panel
    }

    private func storedHorizontalWidth(defaultWidth: CGFloat, screenWidth: CGFloat) -> CGFloat {
        let storedWidth = UserDefaults.standard.double(forKey: PersistenceKeys.horizontalRulerFrame)
        var width = storedWidth > 0 ? storedWidth : defaultWidth
        if width > screenWidth * 0.8 {
            width = screenWidth / 3.0
        }
        width = max(width, Constants.minHRulerWidth)
        return min(width, screenWidth)
    }
    
    func startObserving() {
        self.syncMagnifierVisibility()
        self.startMagnificationObservation()
    }

    @MainActor
    private func startMagnificationObservation() {
        magnificationObservationTask?.cancel()
        magnificationObservationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            withObservationTracking {
                _ = self.magnificationViewModel.isMagnifierVisible
            } onChange: { [weak self] in
                Task { @MainActor in
                    self?.startObserving()
                }
            }
        }
    }

    private func syncMagnifierVisibility() {
        if magnificationViewModel.isMagnifierVisible {
            showMagnifierWindow()
        } else {
            hideMagnifierWindow()
        }
    }

    private func showMagnifierWindow() {
        if magnifierController == nil {
            let window = makeMagnifierWindow()
            magnifierController = NSWindowController(window: window)
        }
        magnifierController?.showWindow(nil)
        magnifierController?.window?.makeKeyAndOrderFront(nil)
    }

    private func hideMagnifierWindow() {
        magnifierController?.window?.orderOut(nil)
    }

    private func makeMagnifierWindow() -> NSWindow {
        let size = NSSize(width: 240, height: 240)
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let origin = NSPoint(
            x: screenFrame.minX + (screenFrame.width - size.width) / 2.0,
            y: screenFrame.minY + max((screenFrame.height / 2.0 - size.height) / 2.0, 0)
        )
        let window = NSWindow(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Magnification"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 180, height: 180)
        window.contentView = NSHostingView(rootView: MagnificationWindowView(viewModel: magnificationViewModel))
        window.delegate = magnifierWindowDelegate
        return window
    }
}

final class MagnifierWindowDelegate: NSObject, NSWindowDelegate {
    private let viewModel: MagnificationViewModel

    init(viewModel: MagnificationViewModel) {
        self.viewModel = viewModel
    }

    func windowWillClose(_ notification: Notification) {
        viewModel.isMagnifierVisible = false
    }
}



struct VerticalRulerView: View {
    @Bindable var debugSettings: DebugSettingsModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
            VStack(spacing: 12) {
                Text("Vertical")
                Spacer()
                Text("Ruler")
            }
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            debugSettings.showWindowBackground
            ? Color.black.opacity(0.15)
            : Color.clear
        )
    }
}
