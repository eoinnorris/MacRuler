//
//  ScreenSelectionMagnifierView.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-01.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ScreenSelectionMagnifierView: View {
    @Bindable var session: SelectionSession
    let appDelegate: AppDelegate?
    @Bindable var magnificationViewModel: MagnificationViewModel
    @State private var controller = StreamCaptureObserver()
    @State private var selectionPreviewWindow: NSWindow?
    @State private var selectionPreviewTask: Task<Void, Never>?

    var horizontalOverlayViewModel: OverlayViewModel
    var verticalOverlayViewModel: OverlayVerticalViewModel

    var body: some View {
        SelectionMagnifierContentView(session: session,
                                      controller: controller,
                                      magnificationViewModel: magnificationViewModel,
                                      horizontalOverlayViewModel:horizontalOverlayViewModel,
                                      verticalOverlayViewModel:verticalOverlayViewModel)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .toolbar {
            ScreenSelectionMagnifierToolbar(
                session: session,
                snapshotAction: takeSnapshot,
                canTakeSnapshot: controller.frameImage != nil
            )
        }
        .onChange(of: session.showSelection) { _, shouldShow in
            if shouldShow {
                presentSelectionWindowTemporarily()
            } else {
                selectionPreviewTask?.cancel()
                dismissSelectionWindow()
            }
        }
        .onChange(of: session.showHorizontalRuler) { _, shouldShow in
            handleHorizontalRulerToggle(isOn: shouldShow)
        }
        .onChange(of: session.showVerticalRuler) { _, shouldShow in
            handleVerticalRulerToggle(isOn: shouldShow)
        }
        .onAppear {
            syncRulerToggleStateWithVisibility()
            let normalizedMagnification = magnificationViewModel.normalizedMagnification(session.magnification)
            session.magnification = normalizedMagnification
            magnificationViewModel.magnification = normalizedMagnification
        }
        .onReceive(NotificationCenter.default.publisher(for: .rulerVisibilityDidChange)) { notification in
            syncRulerToggleStateWithVisibility(from: notification)
        }
        .onChange(of: session.magnification) { _, newValue in
            let normalizedValue = magnificationViewModel.normalizedMagnification(newValue)
            if normalizedValue != newValue {
                session.magnification = normalizedValue
                return
            }
            magnificationViewModel.magnification = normalizedValue
        }
        .onDisappear {
            selectionPreviewTask?.cancel()
            dismissSelectionWindow()
            session.showHorizontalRuler = false
            session.showVerticalRuler = false
            appDelegate?.setHorizontalRulerVisible(false)
            appDelegate?.setVerticalRulerVisible(false)
        }
    }

    @MainActor
    private func syncRulerToggleStateWithVisibility(from notification: Notification? = nil) {
        if let horizontalVisible = notification?.userInfo?["horizontalVisible"] as? Bool,
           let verticalVisible = notification?.userInfo?["verticalVisible"] as? Bool {
            session.showHorizontalRuler = horizontalVisible
            session.showVerticalRuler = verticalVisible
            return
        }

        guard let appDelegate else { return }
        session.showHorizontalRuler = appDelegate.isHorizontalRulerVisible()
        session.showVerticalRuler = appDelegate.isVerticalRulerVisible()
    }

    @MainActor
    private func handleHorizontalRulerToggle(isOn: Bool) {
        guard let appDelegate else { return }
        if isOn, let frame = magnifierWindowFrame() {
            appDelegate.positionHorizontalRuler(aboveSelectionMagnifierFrame: frame)
        }
        appDelegate.setHorizontalRulerVisible(isOn)
    }

    @MainActor
    private func handleVerticalRulerToggle(isOn: Bool) {
        guard let appDelegate else { return }
        if isOn, let frame = magnifierWindowFrame() {
            appDelegate.positionVerticalRuler(aboveAndLeftOfSelectionMagnifierFrame: frame)
        }
        appDelegate.setVerticalRulerVisible(isOn)
    }

    @MainActor
    private func magnifierWindowFrame() -> CGRect? {
        if let window = NSApplication.shared.keyWindow,
           window.title == "Selection Magnification" {
            return window.frame
        }

        return NSApplication.shared.windows.first(where: { $0.title == "Selection Magnification" })?.frame
    }

    private func takeSnapshot() {
        guard let frameImage = controller.frameImage else { return }

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "selection-snapshot.png"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let imageRep = NSBitmapImageRep(cgImage: frameImage)
        guard let data = imageRep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: url)
    }

    @MainActor
    private func presentSelectionWindowTemporarily() {
        selectionPreviewTask?.cancel()
        dismissSelectionWindow()

        let rect = selectionRectInScreenCoordinates()
        guard rect.width > 2, rect.height > 2 else {
            session.showSelection = false
            return
        }

        let window = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.contentView = NSHostingView(
            rootView: TemporarySelectionWindowContent()
        )

        selectionPreviewWindow = window
        window.makeKeyAndOrderFront(nil)

        selectionPreviewTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            dismissSelectionWindow()
            if session.showSelection {
                session.showSelection = false
            }
        }
    }

    @MainActor
    private func dismissSelectionWindow() {
        selectionPreviewWindow?.orderOut(nil)
        selectionPreviewWindow = nil
    }

    private func selectionRectInScreenCoordinates() -> CGRect {
        return session.selectionRectGlobal
//        guard let screen = session.screen else { return session.selectionRectGlobal }
//        return Constants.scRectToGlobalRect(session.selectionRectGlobal, containerHeight: screen.frame.height)
    }

    private func selectionRectInGlobalCoordinates() -> CGRect {
        guard let screen = session.screen else { return session.selectionRectGlobal }
        return Constants.scRectToGlobalRect(session.selectionRectGlobal, containerHeight: screen.frame.height)
    }
}

private struct TemporarySelectionWindowContent: View {
    var body: some View {
        Rectangle()
            .stroke(
                Color.white.opacity(0.95),
                style: StrokeStyle(lineWidth: 2, dash: [6, 4])
            )
            .background(Color.clear)
    }
}
