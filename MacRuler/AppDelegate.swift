//
//  AppDelegate.swift
//  MacRuler
//
//  Created by Eoin Kortext on 05/02/2026.
//

import SwiftUI
import AppKit
import Observation

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    static weak var shared: AppDelegate?

    private var horizontalController: NSWindowController?
    private var verticalController: NSWindowController?
    private var magnifierController: NSWindowController?
    private var selectionMagnifierController: NSWindowController?
    private var selectionOverlayController: NSWindowController?
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private var horizontalMenuItem: NSMenuItem?
    private var verticalMenuItem: NSMenuItem?
    private var magnifierMenuItem: NSMenuItem?
    private let horizontalResizeDelegate = HorizontalRulerWindowDelegate(fixedHeight: Constants.horizontalHeight)
    private let magnificationViewModel = MagnificationViewModel.shared
    private let captureController = CaptureController()
    private let selectionMagnificationViewModel = MagnificationViewModel.selection
    private lazy var magnifierWindowDelegate = MagnifierWindowDelegate { [weak self] in
        self?.magnificationViewModel.isMagnifierVisible = false
    }
    private lazy var selectionMagnifierWindowDelegate = MagnifierWindowDelegate { [weak self] in
        self?.selectionMagnificationViewModel.isSelectionMagnifierVisible = false
    }
    private let rulerSettingsViewModel = RulerSettingsViewModel.shared
    private var magnificationObservationTask: Task<Void, Never>?
    private var selectionMagnificationObservationTask: Task<Void, Never>?
    private var rulerAttachmentObservationTask: Task<Void, Never>?
    private var rulerWindowObservationTokens: [NSObjectProtocol] = []
    private weak var lastActiveRulerWindow: NSWindow?

    
    func makeHorizontalRulerView() -> some View {
        HorizontalRulerView(overlayViewModel: OverlayViewModel.shared,
                            settings: RulerSettingsViewModel.shared,
                            debugSettings: DebugSettingsModel.shared,
                            magnificationViewModel: MagnificationViewModel.shared)
            .frame(height: Constants.horizontalHeight)
            .fixedSize(horizontal: false, vertical: true)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
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
        let vBaseHeight = min(700, vf.height - 40)
        let vSize = NSSize(
            width: Constants.verticalWidth,
            height: vBaseHeight + Constants.verticalReadoutHeight
        )
        let vOrigin = NSPoint(
            x: vf.minX + 10,
            y: vf.minY + (vf.height - vSize.height) / 2
        )
        let vPanel = makePanel(
            frame: NSRect(origin: vOrigin, size: vSize),
            rootView: VerticalRulerView(
                overlayViewModel: OverlayVerticalViewModel.shared,
                settings: RulerSettingsViewModel.shared,
                debugSettings: DebugSettingsModel.shared
            )
        )
        verticalController = NSWindowController(window: vPanel)
        verticalController?.showWindow(nil)

        setupStatusItem()
        startMagnificationObservation()
        syncMagnifierVisibility()
        startSelectionMagnificationObservation()
        syncSelectionMagnifierVisibility()
        startRulerAttachmentObservation()
        startRulerWindowObservation()
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

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "ruler", accessibilityDescription: "MacRuler")
        }
        let menu = NSMenu()
        menu.delegate = self

        let horizontalItem = NSMenuItem(title: "Show Horizontal Ruler", action: #selector(toggleHorizontalRuler), keyEquivalent: "")
        horizontalItem.target = self
        menu.addItem(horizontalItem)
        horizontalMenuItem = horizontalItem

        let verticalItem = NSMenuItem(title: "Show Vertical Ruler", action: #selector(toggleVerticalRuler), keyEquivalent: "")
        verticalItem.target = self
        menu.addItem(verticalItem)
        verticalMenuItem = verticalItem

        let magnifierItem = NSMenuItem(title: "Show Magnification", action: #selector(toggleMagnifier), keyEquivalent: "")
        magnifierItem.target = self
        menu.addItem(magnifierItem)
        magnifierMenuItem = magnifierItem

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit MacRuler", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
        statusMenu = menu
        refreshStatusMenu()
    }

    private func refreshStatusMenu() {
        if let window = horizontalController?.window {
            horizontalMenuItem?.title = window.isVisible ? "Hide Horizontal Ruler" : "Show Horizontal Ruler"
            horizontalMenuItem?.state = window.isVisible ? .on : .off
        }
        if let window = verticalController?.window {
            verticalMenuItem?.title = window.isVisible ? "Hide Vertical Ruler" : "Show Vertical Ruler"
            verticalMenuItem?.state = window.isVisible ? .on : .off
        }
        magnifierMenuItem?.title = magnificationViewModel.isMagnifierVisible ? "Hide Magnification" : "Show Magnification"
        magnifierMenuItem?.state = magnificationViewModel.isMagnifierVisible ? .on : .off
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshStatusMenu()
    }

    @objc private func toggleHorizontalRuler() {
        guard let window = horizontalController?.window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
        }
        refreshStatusMenu()
    }

    @objc private func toggleVerticalRuler() {
        guard let window = verticalController?.window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
        }
        refreshStatusMenu()
    }

    @objc private func toggleMagnifier() {
        magnificationViewModel.isMagnifierVisible.toggle()
        refreshStatusMenu()
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
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

    func startSelectionObserving() {
        self.syncSelectionMagnifierVisibility()
        self.startSelectionMagnificationObservation()
    }

    @MainActor
    private func startMagnificationObservation() {
        magnificationObservationTask?.cancel()
        magnificationObservationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            withObservationTracking {
                _ = self.magnificationViewModel.isMagnifierVisible
            } onChange: { [weak self] in
                guard let localSelf = self else { return }
                Task { @MainActor in
                    localSelf.startObserving()
                }
            }
        }
    }

    @MainActor
    private func startSelectionMagnificationObservation() {
        selectionMagnificationObservationTask?.cancel()
        selectionMagnificationObservationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            withObservationTracking {
                _ = self.selectionMagnificationViewModel.isSelectionMagnifierVisible
            } onChange: { [weak self] in
                guard let localSelf = self else { return }
                Task { @MainActor in
                    localSelf.startSelectionObserving()
                }
            }
        }
    }

    @MainActor
    private func startRulerWindowObservation() {
        rulerWindowObservationTokens.forEach { NotificationCenter.default.removeObserver($0) }
        rulerWindowObservationTokens.removeAll()
        guard let hWindow = horizontalController?.window,
              let vWindow = verticalController?.window else {
            return
        }
        let center = NotificationCenter.default
        let notifications: [NSNotification.Name] = [
            NSWindow.didBecomeKeyNotification,
        ]
        for name in notifications {
            rulerWindowObservationTokens.append(
                center.addObserver(forName: name, object: hWindow, queue: .main) { [weak self] notification in
                    guard let window = notification.object as? NSWindow else { return }
                    guard let localSelf = self else { return }
                    Task { @MainActor in
                        localSelf.handleRulerWindowActivity(window)
                    }
                }
            )
            rulerWindowObservationTokens.append(
                center.addObserver(forName: name, object: vWindow, queue: .main) { [weak self] notification in
                    guard let window = notification.object as? NSWindow else { return }
                    guard let localSelf = self else { return }
                    Task { @MainActor in
                        localSelf.handleRulerWindowActivity(window)
                    }
                }
            )
        }
    }

    @MainActor
    private func startRulerAttachmentObservation() {
        rulerAttachmentObservationTask?.cancel()
        rulerAttachmentObservationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            withObservationTracking {
                _ = self.rulerSettingsViewModel.attachBothRulers
            } onChange: { [weak self] in
                guard let localSelf = self else { return }
                Task { @MainActor in
                    localSelf.handleRulerAttachmentChange()
                    localSelf.startRulerAttachmentObservation()
                }
            }
        }
    }

    @MainActor
    private func handleRulerAttachmentChange() {
        if rulerSettingsViewModel.attachBothRulers {
            if let activeWindow = lastActiveRulerWindow {
                updateDynamicRulerAttachment(for: activeWindow)
            }
        } else {
            releaseRulerWindowAttachments()
        }
    }

    @MainActor
    private func handleRulerWindowActivity(_ window: NSWindow) {
        guard let hWindow = horizontalController?.window,
              let vWindow = verticalController?.window else {
            return
        }
        guard window == hWindow || window == vWindow else { return }
        lastActiveRulerWindow = window
        guard rulerSettingsViewModel.attachBothRulers else { return }
        updateDynamicRulerAttachment(for: window)
    }
    
    enum RulerAttachmwnt {
        case H2V
        case V2H
    }

    @MainActor
    private func updateDynamicRulerAttachment(for activeWindow: NSWindow) {
        guard let hWindow = horizontalController?.window,
              let vWindow = verticalController?.window else {
            return
        }
                
        let parentWindow: NSWindow
        let childWindow: NSWindow
        if activeWindow == hWindow {
            parentWindow = hWindow
            childWindow = vWindow
        } else if activeWindow == vWindow {
            parentWindow = vWindow
            childWindow = hWindow
        } else {
            return
        }
        if let parent = hWindow.parent { parent.removeChildWindow(hWindow) }
        if let parent = vWindow.parent { parent.removeChildWindow(vWindow) }
        parentWindow.addChildWindow(childWindow, ordered: .above)
    }

    @MainActor
    private func releaseRulerWindowAttachments() {
        guard let hWindow = horizontalController?.window,
              let vWindow = verticalController?.window else {
            return
        }
        if let children = hWindow.childWindows, children.contains(vWindow) {
            hWindow.removeChildWindow(vWindow)
        }
        if let children = vWindow.childWindows, children.contains(hWindow) {
            vWindow.removeChildWindow(hWindow)
        }
        if let parent = hWindow.parent {
            parent.removeChildWindow(hWindow)
        }
        if let parent = vWindow.parent {
            parent.removeChildWindow(vWindow)
        }
    }


    private func syncMagnifierVisibility() {
        if magnificationViewModel.isMagnifierVisible {
            showMagnifierWindow()
        } else {
            hideMagnifierWindow()
        }
    }

    private func syncSelectionMagnifierVisibility() {
        if selectionMagnificationViewModel.isSelectionMagnifierVisible {
            showSelectionMagnifierWindow()
        } else {
            hideSelectionMagnifierWindow()
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

    private func showSelectionMagnifierWindow() {
        if selectionMagnifierController == nil {
            let window = makeSelectionMagnifierWindow()
            selectionMagnifierController = NSWindowController(window: window)
        }
        selectionMagnifierController?.showWindow(nil)
        selectionMagnifierController?.window?.makeKeyAndOrderFront(nil)
    }

    private func hideMagnifierWindow() {
        magnifierController?.window?.orderOut(nil)
    }

    private func hideSelectionMagnifierWindow() {
        selectionMagnifierController?.window?.orderOut(nil)
    }

    private func makeMagnifierWindow() -> NSWindow {
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let defaultWidth = screenFrame == .zero ? 240 : screenFrame.width / 3.0
        let size = NSSize(width: defaultWidth, height: 240)
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
        window.minSize = NSSize(width: 240, height: 180)
        window.contentView = NSHostingView(rootView: MagnificationWindowView(viewModel: magnificationViewModel))
        window.delegate = magnifierWindowDelegate
        return window
    }

    private func makeSelectionMagnifierWindow() -> NSWindow {
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let defaultWidth = screenFrame == .zero ? 240 : screenFrame.width / 3.0
        let size = NSSize(width: defaultWidth, height: 240)
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
        window.title = "Selection Magnification"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 240, height: 180)
        window.contentView = NSHostingView(rootView: ScreenSelectionMagnifierView(viewModel: selectionMagnificationViewModel))
        window.delegate = selectionMagnifierWindowDelegate
        return window
    }

    @MainActor
    func beginWindowSelection() {
        captureController.beginWindowSelection()
    }
    
    @MainActor
    func beginScreenSelection() {
        guard let screen = NSScreen.main else { return }
        let overlay = makeSelectionOverlayWindow(for: screen)
        selectionOverlayController = NSWindowController(window: overlay)
        selectionOverlayController?.showWindow(nil)
        selectionOverlayController?.window?.makeKeyAndOrderFront(nil)
    }

    @MainActor
    private func finishScreenSelection() {
        selectionOverlayController?.window?.orderOut(nil)
        selectionOverlayController = nil
    }

    private func makeSelectionOverlayWindow(for screen: NSScreen) -> NSWindow {
        let overlay = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        overlay.level = .floating
        overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlay.isOpaque = false
        overlay.backgroundColor = .clear
        overlay.ignoresMouseEvents = false
        overlay.hidesOnDeactivate = false
        overlay.hasShadow = false
        overlay.contentView = NSHostingView(
            rootView: ScreenSelectionOverlayView(
                onSelection: { [weak self] selectionRect, screen in
                    guard let self else { return }
                    guard let screen else { return }
                    let globalFrame = Constants.globalRectToSCRect(selectionRect, containerHeight: screen.frame.height)
                    
                    self.selectionMagnificationViewModel.rulerFrame = globalFrame
                    self.selectionMagnificationViewModel.screen = screen
                    self.selectionMagnificationViewModel.isSelectionMagnifierVisible = true
                    self.finishScreenSelection()
                },
                onCancel: { [weak self] in
                    self?.finishScreenSelection()
                }
            )
        )
        return overlay
    }
}
