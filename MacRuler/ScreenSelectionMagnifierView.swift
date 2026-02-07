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
    @State private var controller = StreamCaptureObserver()
    @State private var selectionPreviewWindow: NSWindow?
    @State private var selectionPreviewTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 10) {
            SelectionWindowToolbar(
                session: session,
                snapshotAction: takeSnapshot,
                canTakeSnapshot: controller.frameImage != nil
            )
            SelectionMagnifierContentView(session: session, controller: controller)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(12)
        .onChange(of: session.showSelection) { _, shouldShow in
            if shouldShow {
                presentSelectionWindowTemporarily()
            } else {
                selectionPreviewTask?.cancel()
                dismissSelectionWindow()
            }
        }
        .onDisappear {
            selectionPreviewTask?.cancel()
            dismissSelectionWindow()
        }
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

        let rect = selectionRectInGlobalCoordinates()
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
