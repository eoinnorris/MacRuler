//
//  AppDelegate.swift
//  MacRuler
//
//  Created by Eoin Kortext on 05/02/2026.
//

import SwiftUI
import AppKit
import Observation

private final class SelectionOverlayWindow: NSPanel {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onEscape?()
            return
        }
        super.keyDown(with: event)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    static weak var shared: AppDelegate?

    private var horizontalController: NSWindowController?
    private var verticalController: NSWindowController?
    private var magnifierController: NSWindowController?
    private var selectionMagnifierController: NSWindowController?
    private var selectionMagnifierWindowDelegate: MagnifierWindowDelegate?
    private var currentSelectionSession: SelectionSession?
    private var selectionOverlayController: NSWindowController?
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private var horizontalMenuItem: NSMenuItem?
    private var verticalMenuItem: NSMenuItem?
    private var magnifierMenuItem: NSMenuItem?
    private let horizontalResizeDelegate = HorizontalRulerWindowDelegate(fixedHeight: Constants.horizontalHeight)
    private let magnificationViewModel = MagnificationViewModel.shared
    private let captureController = CaptureController()
    private lazy var magnifierWindowDelegate = MagnifierWindowDelegate { [weak self] in
        self?.magnificationViewModel.isMagnifierVisible = false
    }
    private let rulerSettingsViewModel = RulerSettingsViewModel.shared
    private var magnificationObservationTask: Task<Void, Never>?
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
        hPanel.orderOut(nil)

        
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
        vPanel.orderOut(nil)

        setupStatusItem()
        startMagnificationObservation()
        syncMagnifierVisibility()
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

    @MainActor
    func isHorizontalRulerVisible() -> Bool {
        horizontalController?.window?.isVisible ?? false
    }

    @MainActor
    func isVerticalRulerVisible() -> Bool {
        verticalController?.window?.isVisible ?? false
    }

    @MainActor
    func setHorizontalRulerVisible(_ visible: Bool) {
        guard let window = horizontalController?.window else { return }
        if visible {
            window.makeKeyAndOrderFront(nil)
        } else {
            window.orderOut(nil)
        }
        refreshStatusMenu()
    }

    @MainActor
    func setVerticalRulerVisible(_ visible: Bool) {
        guard let window = verticalController?.window else { return }
        if visible {
            window.makeKeyAndOrderFront(nil)
        } else {
            window.orderOut(nil)
        }
        refreshStatusMenu()
    }

    @MainActor
    func positionRulers(aroundSelectionMagnifierFrame frame: CGRect) {
        positionHorizontalRuler(aboveSelectionMagnifierFrame: frame)
        positionVerticalRuler(aboveAndLeftOfSelectionMagnifierFrame: frame)
    }

    @MainActor
    func positionHorizontalRuler(aboveSelectionMagnifierFrame frame: CGRect) {
        guard let window = horizontalController?.window else { return }
        var rulerFrame = window.frame
        let centerXOffset = frame.width * Constants.selectionHorizontalRulerThirdsYOffsetFactor
        rulerFrame.origin.x = frame.origin.x - centerXOffset
        rulerFrame.origin.y = frame.origin.y - 20.0
        window.setFrame(rulerFrame, display: true)
    }

    @MainActor
    func positionVerticalRuler(aboveAndLeftOfSelectionMagnifierFrame frame: CGRect) {
        guard let window = verticalController?.window else { return }
        var rulerFrame = window.frame
        rulerFrame.origin.x = frame.minX - rulerFrame.width - Constants.selectionVerticalRulerLeadingSpacing
        rulerFrame.origin.y = frame.maxY + Constants.selectionRulerTopSpacing
        window.setFrame(rulerFrame, display: true)
    }

    @objc private func toggleHorizontalRuler() {
        setHorizontalRulerVisible(!isHorizontalRulerVisible())
    }

    @objc private func toggleVerticalRuler() {
        setVerticalRulerVisible(!isVerticalRulerVisible())
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

    private func showSelectionMagnifierWindow(for session: SelectionSession) {
        currentSelectionSession?.isWindowVisible = false
        currentSelectionSession = session
        session.showHorizontalRuler = isHorizontalRulerVisible()
        session.showVerticalRuler = isVerticalRulerVisible()

        if let controller = selectionMagnifierController,
           let window = controller.window {
            window.contentView = NSHostingView(rootView: ScreenSelectionMagnifierView(session: session))
            window.title = "Selection Magnification"
            controller.showWindow(nil)
            window.makeKeyAndOrderFront(nil)
            session.isWindowVisible = true
            return
        }

        let window = makeSelectionMagnifierWindow(for: session)
        let controller = NSWindowController(window: window)
        selectionMagnifierController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        session.isWindowVisible = true
    }

    private func hideSelectionMagnifierWindow() {
        selectionMagnifierController?.window?.orderOut(nil)
        currentSelectionSession?.isWindowVisible = false
    }

    private func closeSelectionSession() {
        hideSelectionMagnifierWindow()
        selectionMagnifierController = nil
        selectionMagnifierWindowDelegate = nil
        currentSelectionSession = nil
    }

    private func makeSelectionMagnifierWindow(for session: SelectionSession) -> NSWindow {
        let screenFrame = session.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
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
        window.contentView = NSHostingView(rootView: ScreenSelectionMagnifierView(session: session))

        let delegate = MagnifierWindowDelegate { [weak self] in
            self?.closeSelectionSession()
        }
        selectionMagnifierWindowDelegate = delegate
        window.delegate = delegate
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
        let overlay = SelectionOverlayWindow(
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
        overlay.onEscape = { [weak self] in
            self?.finishScreenSelection()
        }
        overlay.contentView = NSHostingView(
            rootView: ScreenSelectionOverlayView(
                onSelection: { [weak self] selectionRect, screen in
                    guard let self else { return }
                    guard let screen else { return }
                    let globalFrame = Constants.globalRectToSCRect(selectionRect, containerHeight: screen.frame.height)
                    
                    let session = SelectionSession(
                        selectionRecScreen: selectionRect,
                        selectionRectGlobal: globalFrame,
                        screen: screen
                    )
                    self.showSelectionMagnifierWindow(for: session)
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
