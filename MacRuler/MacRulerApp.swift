//
//  MacRulerApp.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//

import SwiftUI
import AppKit

@main
struct MacOSRulerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No default window; we’ll drive our own panels.
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var horizontalController: NSWindowController?
    private var verticalController: NSWindowController?
    private let horizontalResizeDelegate = FixedHeightResizeDelegate(fixedHeight: 44)
    private let horizontalRulerView  = HorizontalRulerView()

    
    func makeHorizontalRulerView() -> some View {
        HorizontalRulerView()
            .frame(height: 44)
            .fixedSize(horizontal: false, vertical: true)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Optional: make it behave like a menu-bar-ish utility app (no Dock icon)
        // Comment this out if you *do* want a normal app presence.
        NSApp.setActivationPolicy(.accessory)

        guard let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame  // avoids menu bar + dock

        // Horizontal panel (top area)
        let hSize = NSSize(width: min(450, vf.width - 40), height: 44)
        let hOrigin = NSPoint(
            x: vf.minX + (vf.width - hSize.width) / 2,
            y: vf.maxY - hSize.height - 10
        )
        let hPanel = makePanel(
            frame: NSRect(origin: hOrigin, size: hSize),
            rootView: makeHorizontalRulerView()
        )
        horizontalController = NSWindowController(window: hPanel)
        horizontalController?.showWindow(nil)
                    
        
        
        
        hPanel.delegate = horizontalResizeDelegate
        hPanel.maxSize = NSSize(width: 1000, height: 44)
        hPanel.contentMaxSize = NSSize(width: 1000, height: 44)

        // Vertical panel (left area)
        let vSize = NSSize(width: 44, height: min(700, vf.height - 40))
        let vOrigin = NSPoint(
            x: vf.minX + 10,
            y: vf.minY + (vf.height - vSize.height) / 2
        )
        let vPanel = makePanel(
            frame: NSRect(origin: vOrigin, size: vSize),
            rootView: VerticalRulerView()
        )
        verticalController = NSWindowController(window: vPanel)
        verticalController?.showWindow(nil)
    }

    private func makePanel<Content: View>(
        frame: NSRect,
        rootView: Content
    ) -> NSWindow {
        let panel = NSWindow(
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
}



struct VerticalRulerView: View {
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
    }
}
