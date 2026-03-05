//
//  AppDelegate.swift
//  MacRuler
//
//  Created by Eoin Kortext on 05/02/2026.
//

import SwiftUI
import AppKit
import Observation
@preconcurrency import ScreenCaptureKit

extension Notification.Name {
    static let rulerVisibilityDidChange = Notification.Name("rulerVisibilityDidChange")
}

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

private final class ScreenSelectionWindow: NSPanel {
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


private final class SelectionWindowDelegate: NSObject, NSWindowDelegate {
    let onFrameChange: (CGRect, NSScreen?) -> Void

    init(onFrameChange: @escaping (CGRect, NSScreen?) -> Void) {
        self.onFrameChange = onFrameChange
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        onFrameChange(window.frame, window.screen)
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        onFrameChange(window.frame, window.screen)
    }
}

private struct ScreenSelectionWindowChromeView: View {
    var body: some View {
        GeometryReader { geometry in
            let insetRect = CGRect(origin: .zero, size: geometry.size).insetBy(dx: 0.5, dy: 0.5)

            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                SelectionDancingAntsRectangle(rect: insetRect)
            }
            .allowsHitTesting(false)
        }
        .background(Color.clear)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    enum RulerBackgroundLockReason: Hashable {
        case dividerHover
        case dividerDrag
        case manualToggle
    }

    /// Weak process-wide reference for bridging legacy AppKit actions into SwiftUI callbacks.
    /// This is assigned during launch on the main thread and should be read from UI/MainActor code only.
    static weak var shared: AppDelegate?

    private var horizontalController: NSWindowController?
    private var verticalController: NSWindowController?
    private var selectionMagnifierController: NSWindowController?
    private var selectionMagnifierWindowDelegate: MagnifierWindowDelegate?
    @MainActor private var currentSelectionSession: SelectionSession?
    private var selectionBackdropController: NSWindowController?
    private var selectionWindowController: NSWindowController?
    private var selectionClickMonitor: Any?
    private var selectionEscapeMonitor: Any?
    private var selectionWindowDelegate: SelectionWindowDelegate?
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private var horizontalMenuItem: NSMenuItem?
    private var verticalMenuItem: NSMenuItem?
    private let horizontalResizeDelegate = HorizontalRulerWindowDelegate(fixedHeight: Constants.horizontalHeight)
    private let captureController = CaptureController()
    @MainActor private let selectionCaptureObserver = StreamCaptureObserver()
    private let dependencies = AppDependencies.live
    private lazy var rulerSettingsViewModel = dependencies.rulerSettings
    private var rulerAttachmentObservationTask: Task<Void, Never>?
    private var rulerLockObservationTask: Task<Void, Never>?
    private var rulerWindowObservationTokens: [NSObjectProtocol] = []
    private weak var lastActiveRulerWindow: NSWindow?
    private var horizontalBackgroundLockReasons: Set<RulerBackgroundLockReason> = []
    private var verticalBackgroundLockReasons: Set<RulerBackgroundLockReason> = []
       
    func makeHorizontalRulerView() -> some View {
        HorizontalRulerView(overlayViewModel: dependencies.overlay,
                            settings: dependencies.rulerSettings,
                            debugSettings: dependencies.debugSettings,
                            magnificationViewModel: dependencies.magnification)
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
        let defaultWidth = min(550, vf.width - 40)
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
                overlayViewModel: dependencies.overlayVertical,
                settings: dependencies.rulerSettings,
                debugSettings: dependencies.debugSettings,
                magnificationViewModel: dependencies.magnification
            )
        )
        verticalController = NSWindowController(window: vPanel)
        vPanel.orderOut(nil)

        setupStatusItem()
        startRulerAttachmentObservation()
        startRulerLockObservation()
        handleRulerLockChange()
        startRulerWindowObservation()
        configureCaptureControllerCallbacks()
        showSelectionMagnifierWindow()
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
        postRulerVisibilityDidChange()
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
        postRulerVisibilityDidChange()
    }

    @MainActor
    func setHorizontalRulerBackgroundMovable(_ movable: Bool) {
        guard let window = horizontalController?.window else { return }
        window.isMovableByWindowBackground = movable
    }
    
    var isHorizontalRulerBackgroundMovable: Bool {
        (horizontalController?.window?.isMovableByWindowBackground ?? false)
    }
    
    var isVerticalRulerBackgroundMovable: Bool {
        (verticalController?.window?.isMovableByWindowBackground ?? false)
    }

    @MainActor
    func setHorizontalRulerBackgroundLocked(_ isLocked: Bool, reason: RulerBackgroundLockReason) {
        updateBackgroundLockReasons(
            &horizontalBackgroundLockReasons,
            isLocked: isLocked,
            reason: reason,
            movableSetter: setHorizontalRulerBackgroundMovable
        )
    }

    @MainActor
    func isHorizontalRulerBackgroundLocked() -> Bool {
        !horizontalBackgroundLockReasons.isEmpty
    }

    @MainActor
    func setVerticalRulerBackgroundMovable(_ movable: Bool) {
        guard let window = verticalController?.window else { return }
        window.isMovableByWindowBackground = movable
    }

    @MainActor
    func setVerticalRulerBackgroundLocked(_ isLocked: Bool, reason: RulerBackgroundLockReason) {
        updateBackgroundLockReasons(
            &verticalBackgroundLockReasons,
            isLocked: isLocked,
            reason: reason,
            movableSetter: setVerticalRulerBackgroundMovable
        )
    }

    @MainActor
    func isVerticalRulerBackgroundLocked() -> Bool {
        !verticalBackgroundLockReasons.isEmpty
    }

    @MainActor
    private func updateBackgroundLockReasons(
        _ reasons: inout Set<RulerBackgroundLockReason>,
        isLocked: Bool,
        reason: RulerBackgroundLockReason,
        movableSetter: (Bool) -> Void
    ) {
        let hasReason = reasons.contains(reason)
        guard hasReason != isLocked else { return }

        if isLocked {
            reasons.insert(reason)
        } else {
            reasons.remove(reason)
        }

        movableSetter(reasons.isEmpty)
    }

    @MainActor
    private func postRulerVisibilityDidChange() {
        NotificationCenter.default.post(
            name: .rulerVisibilityDidChange,
            object: self,
            userInfo: [
                "horizontalVisible": isHorizontalRulerVisible(),
                "verticalVisible": isVerticalRulerVisible()
            ]
        )
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

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }


    @MainActor
    func increaseSelectionMagnification() {
        adjustSelectionMagnification(increasing: true)
    }

    @MainActor
    func decreaseSelectionMagnification() {
        adjustSelectionMagnification(increasing: false)
    }

    @MainActor
    private func adjustSelectionMagnification(increasing: Bool) {
        guard NSApp.isActive else { return }
        guard let session = currentSelectionSession, session.isWindowVisible else { return }

        let nextMagnification = increasing
            ? dependencies.magnification.increaseMagnification()
            : dependencies.magnification.decreaseMagnification()

        dependencies.magnification.magnification = nextMagnification
        session.magnification = nextMagnification
    }

    private func configureCaptureControllerCallbacks() {
        captureController.onDidUpdateFilter = { [weak self] filter in
            Task { @MainActor [weak self] in
                self?.handleWindowSelection(filter: filter)
            }
        }
    }

    @MainActor
    private func handleWindowSelection(filter: SCContentFilter) {
        let selectionRect = filter.contentRect
        guard selectionRect.width > 1, selectionRect.height > 1 else { return }

        let screen = screenForFilter(filter)
        let containerHeight = screen?.frame.height ?? selectionRect.maxY
        let globalFrame = Constants.globalRectToSCRect(selectionRect, containerHeight: containerHeight)
        let session = SelectionSession(
            selectionRectScreen: selectionRect,
            selectionRectGlobal: globalFrame,
            screen: screen
        )
        showSelectionMagnifierWindow(for: session)
    }

    private func screenForFilter(_ filter: SCContentFilter) -> NSScreen? {
        guard let display = filter.includedDisplays.first else { return NSScreen.main}
        
        return NSScreen.screens.first { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }
            return number.uint32Value == display.displayID
        } ?? NSScreen.main
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
    private func startRulerLockObservation() {
        rulerLockObservationTask?.cancel()
        rulerLockObservationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            withObservationTracking {
                _ = self.rulerSettingsViewModel.horizontalRulerLocked
                _ = self.rulerSettingsViewModel.verticalRulerLocked
            } onChange: { [weak self] in
                guard let localSelf = self else { return }
                Task { @MainActor in
                    localSelf.handleRulerLockChange()
                    localSelf.startRulerLockObservation()
                }
            }
        }
    }

    @MainActor
    private func handleRulerLockChange() {
        setHorizontalRulerBackgroundLocked(
            rulerSettingsViewModel.horizontalRulerLocked,
            reason: .manualToggle
        )
        setVerticalRulerBackgroundLocked(
            rulerSettingsViewModel.verticalRulerLocked,
            reason: .manualToggle
        )
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
    
    enum RulerAttachment {
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


    @MainActor
    private func showSelectionMagnifierWindow(for session: SelectionSession? = nil) {
        if let session {
            currentSelectionSession?.isWindowVisible = false
            currentSelectionSession = session
            session.showHorizontalRuler = isHorizontalRulerVisible()
            session.showVerticalRuler = isVerticalRulerVisible()
            session.isWindowVisible = true
        }

        if let controller = selectionMagnifierController,
           let window = controller.window {
            window.contentView = NSHostingView(
                rootView: SelectionMagnifierRootView(
                    session: currentSelectionSession,
                    appDelegate: self,
                    selectionCaptureObserver: selectionCaptureObserver,
                    horizontalOverlayViewModel: dependencies.overlay,
                    verticalOverlayViewModel: dependencies.overlayVertical,
                    magnificationViewModel: dependencies.magnification
                )
            )
            window.title = "Selection Magnification"
            controller.showWindow(nil)
            window.makeKeyAndOrderFront(nil)
            currentSelectionSession?.isWindowVisible = true
            return
        }

        let window = makeSelectionMagnifierWindow(session: currentSelectionSession)
        let controller = NSWindowController(window: window)
        selectionMagnifierController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        currentSelectionSession?.isWindowVisible = true
    }

    @MainActor
    private func hideSelectionMagnifierWindow() {
        selectionMagnifierController?.window?.orderOut(nil)
        currentSelectionSession?.isWindowVisible = false
    }

    @MainActor
    private func closeSelectionSession() {
        hideSelectionMagnifierWindow()
        currentSelectionSession = nil
        if let window = selectionMagnifierController?.window {
            window.contentView = NSHostingView(
                rootView: SelectionMagnifierRootView(
                    session: nil,
                    appDelegate: self,
                    selectionCaptureObserver: selectionCaptureObserver,
                    horizontalOverlayViewModel: dependencies.overlay,
                    verticalOverlayViewModel: dependencies.overlayVertical,
                    magnificationViewModel: dependencies.magnification
                )
            )
        }
    }

    @MainActor
    private func makeSelectionMagnifierWindow(session: SelectionSession?) -> NSWindow {
        let screenFrame = session?.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
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
        window.contentView = NSHostingView(
            rootView: SelectionMagnifierRootView(
                session: session,
                appDelegate: self,
                selectionCaptureObserver: selectionCaptureObserver,
                horizontalOverlayViewModel: dependencies.overlay,
                verticalOverlayViewModel: dependencies.overlayVertical,
                magnificationViewModel: dependencies.magnification
            )
        )

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
        selectionCaptureObserver.restartCapture()

        let restoredPlacement = restoreScreenSelectionPlacement()
        guard let screen = restoredPlacement?.screen ?? NSScreen.main else { return }
        finishScreenSelection()

        let backdrop = makeSelectionBackdropWindow(for: screen)
        let selectionWindow = makeScreenSelectionWindow(
            for: screen,
            restoredFrame: restoredPlacement?.frame
        )

        selectionBackdropController = NSWindowController(window: backdrop)
        selectionWindowController = NSWindowController(window: selectionWindow)

        updateSelectionSessionFromSelectionWindowFrame(selectionWindow.frame, on: selectionWindow.screen ?? screen)

        selectionBackdropController?.showWindow(nil)
        selectionWindowController?.showWindow(nil)
        selectionWindowController?.window?.makeKeyAndOrderFront(nil)
        installSelectionEventMonitors()
    }


    @MainActor
    private func updateSelectionSessionFromSelectionWindowFrame(_ frame: CGRect, on screen: NSScreen) {
        if let currentSelectionSession {
            currentSelectionSession.selectionRectScreen = frame
            currentSelectionSession.selectionRectGlobal = Constants.globalRectToSCRect(frame, containerHeight: screen.frame.height)
            currentSelectionSession.screen = screen
            return
        }

        let session = SelectionSession(
            selectionRectScreen: frame,
            selectionRectGlobal: Constants.globalRectToSCRect(frame, containerHeight: screen.frame.height),
            screen: screen
        )
        showSelectionMagnifierWindow(for: session)
    }

    @MainActor
    private func finishScreenSelection() {
        persistScreenSelectionPlacement()
        selectionWindowController?.window?.orderOut(nil)
        selectionBackdropController?.window?.orderOut(nil)
        selectionWindowController = nil
        selectionBackdropController = nil
        if let selectionClickMonitor {
            NSEvent.removeMonitor(selectionClickMonitor)
            self.selectionClickMonitor = nil
        }
        if let selectionEscapeMonitor {
            NSEvent.removeMonitor(selectionEscapeMonitor)
            self.selectionEscapeMonitor = nil
        }
    }

    @MainActor
    private func commitScreenSelection(_ selectionRect: CGRect, on screen: NSScreen) {
        let globalFrame = Constants.globalRectToSCRect(selectionRect, containerHeight: screen.frame.height)

        let session = SelectionSession(
            selectionRectScreen: selectionRect,
            selectionRectGlobal: globalFrame,
            screen: screen
        )
        showSelectionMagnifierWindow(for: session)
        finishScreenSelection()
    }

    final class DraggableContentView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
    }
    
    private func makeSelectionBackdropWindow(for screen: NSScreen) -> NSWindow {
        let overlay = SelectionOverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        overlay.level = .floating
        overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlay.isOpaque = false
        overlay.backgroundColor = NSColor.black.withAlphaComponent(0.2)
        overlay.ignoresMouseEvents = false
        overlay.hidesOnDeactivate = false
        overlay.hasShadow = false
        overlay.isMovableByWindowBackground = false
        overlay.onEscape = { [weak self] in
            self?.finishScreenSelection()
        }

        overlay.isMovableByWindowBackground = true  // optional, but nice
        overlay.contentView = DraggableContentView(frame: CGRect(origin: .zero, size: overlay.frame.size))

        return overlay
    }

    private func makeScreenSelectionWindow(for screen: NSScreen) -> NSWindow {
        makeScreenSelectionWindow(for: screen, restoredFrame: nil)
    }

    private func makeScreenSelectionWindow(for screen: NSScreen, restoredFrame: CGRect?) -> NSWindow {
        let visible = screen.visibleFrame
        let initialFrame = restoredFrame ?? defaultScreenSelectionFrame(for: visible)

        let delegate = SelectionWindowDelegate { [weak self] frame, frameScreen in
            guard let self else { return }
            Task { @MainActor in
                self.updateSelectionSessionFromSelectionWindowFrame(frame, on: frameScreen ?? screen)
            }
        }
        selectionWindowDelegate = delegate

        let selectionWindow = ScreenSelectionWindow(
            contentRect: initialFrame,
            styleMask: [.borderless, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        selectionWindow.level = .floating
        selectionWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        selectionWindow.isOpaque = false
        selectionWindow.backgroundColor = NSColor.red.withAlphaComponent(0.1)
        selectionWindow.hasShadow = false
        selectionWindow.hidesOnDeactivate = false
        selectionWindow.isMovableByWindowBackground = true
        selectionWindow.minSize = NSSize(width: 120, height: 100)
        selectionWindow.onEscape = { [weak self] in
            self?.finishScreenSelection()
        }
        selectionWindow.contentView = NSHostingView(rootView: ScreenSelectionWindowChromeView())
        selectionWindow.delegate = delegate

        return selectionWindow
    }

    private func defaultScreenSelectionFrame(for visibleFrame: CGRect) -> CGRect {
        let initialWidth = max(220, visibleFrame.width * 0.35)
        let initialHeight = max(160, visibleFrame.height * 0.28)
        return CGRect(
            x: visibleFrame.midX - (initialWidth / 2),
            y: visibleFrame.midY - (initialHeight / 2),
            width: initialWidth,
            height: initialHeight
        ).integral
    }

    private func restoreScreenSelectionPlacement() -> (screen: NSScreen, frame: CGRect)? {
        guard
            let storedDisplayID = UserDefaults.standard.object(forKey: PersistenceKeys.screenSelectionWindowDisplayID) as? NSNumber,
            let frameDictionary = UserDefaults.standard.dictionary(forKey: PersistenceKeys.screenSelectionWindowFrame),
            let screen = screen(matchingDisplayID: storedDisplayID.uint32Value),
            let restoredFrame = rect(from: frameDictionary)
        else {
            return nil
        }

        let adjusted = adjustedSelectionFrame(restoredFrame, in: screen.visibleFrame)
        return (screen, adjusted)
    }

    @MainActor
    private func persistScreenSelectionPlacement() {
        guard
            let window = selectionWindowController?.window,
            let screen = window.screen,
            let displayID = screenDisplayID(screen)
        else {
            return
        }

        UserDefaults.standard.set(displayID, forKey: PersistenceKeys.screenSelectionWindowDisplayID)
        UserDefaults.standard.set(dictionary(from: window.frame), forKey: PersistenceKeys.screenSelectionWindowFrame)
    }

    private func adjustedSelectionFrame(_ frame: CGRect, in visibleFrame: CGRect) -> CGRect {
        var adjusted = frame
        adjusted.size.width = min(max(adjusted.width, 120), visibleFrame.width)
        adjusted.size.height = min(max(adjusted.height, 100), visibleFrame.height)

        adjusted.origin.x = min(max(adjusted.minX, visibleFrame.minX), visibleFrame.maxX - adjusted.width)
        adjusted.origin.y = min(max(adjusted.minY, visibleFrame.minY), visibleFrame.maxY - adjusted.height)
        return adjusted.integral
    }

    private func screen(matchingDisplayID displayID: UInt32) -> NSScreen? {
        NSScreen.screens.first { screenDisplayID($0) == displayID }
    }

    private func screenDisplayID(_ screen: NSScreen) -> UInt32? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    private func dictionary(from rect: CGRect) -> [String: Double] {
        [
            "x": Double(rect.origin.x),
            "y": Double(rect.origin.y),
            "width": Double(rect.width),
            "height": Double(rect.height)
        ]
    }

    private func rect(from dictionary: [String: Any]) -> CGRect? {
        guard
            let x = (dictionary["x"] as? NSNumber)?.doubleValue,
            let y = (dictionary["y"] as? NSNumber)?.doubleValue,
            let width = (dictionary["width"] as? NSNumber)?.doubleValue,
            let height = (dictionary["height"] as? NSNumber)?.doubleValue,
            width > 0,
            height > 0
        else {
            return nil
        }

        return CGRect(x: x, y: y, width: width, height: height)
    }

    @MainActor
    private func installSelectionEventMonitors() {
        selectionClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            guard let self else { return event }
            guard let selectionWindow = self.selectionWindowController?.window,
                  let targetScreen = selectionWindow.screen
            else { return event }

            let clickLocation = NSEvent.mouseLocation
            let selectionFrame = selectionWindow.frame
            guard selectionFrame.contains(clickLocation) == false else { return event }
            guard self.distance(from: clickLocation, to: selectionFrame) >= 20 else { return event }

            self.commitScreenSelection(selectionFrame, on: targetScreen)
            return nil
        }

        selectionEscapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            self?.finishScreenSelection()
            return nil
        }
    }

    private func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let deltaX = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let deltaY = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return hypot(deltaX, deltaY)
    }
}
