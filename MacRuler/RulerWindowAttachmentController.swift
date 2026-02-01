//
//  RulerWindowAttachmentController.swift
//  MacRuler
//
//  Created by OpenAI Codex on 30/01/2026.
//

import AppKit

final class RulerWindowAttachmentController {
    private weak var horizontalWindow: NSWindow?
    private weak var verticalWindow: NSWindow?
    private let settings: RulerSettingsViewModel
    private var observers: [NSObjectProtocol] = []
    private var lastHorizontalFrame: CGRect?
    private var lastVerticalFrame: CGRect?
    private var isSyncing = false

    init(settings: RulerSettingsViewModel) {
        self.settings = settings
    }

    func attach(horizontal: NSWindow, vertical: NSWindow) {
        horizontalWindow = horizontal
        verticalWindow = vertical
        lastHorizontalFrame = horizontal.frame
        lastVerticalFrame = vertical.frame
        startObserving()
    }

    private func startObserving() {
        removeObservers()
        let center = NotificationCenter.default
        if let horizontalWindow {
            observers.append(
                center.addObserver(
                    forName: NSWindow.didMoveNotification,
                    object: horizontalWindow,
                    queue: .main
                ) { [weak self] notification in
                    guard let window = notification.object as? NSWindow else { return }
                    self?.handleMove(for: window, isHorizontal: true)
                }
            )
        }
        if let verticalWindow {
            observers.append(
                center.addObserver(
                    forName: NSWindow.didMoveNotification,
                    object: verticalWindow,
                    queue: .main
                ) { [weak self] notification in
                    guard let window = notification.object as? NSWindow else { return }
                    self?.handleMove(for: window, isHorizontal: false)
                }
            )
        }
    }

    private func handleMove(for window: NSWindow, isHorizontal: Bool) {
        if isSyncing {
            updateStoredFrame(for: window, isHorizontal: isHorizontal)
            return
        }

        let previousFrame = isHorizontal ? lastHorizontalFrame : lastVerticalFrame
        updateStoredFrame(for: window, isHorizontal: isHorizontal)
        guard settings.attachRulers else { return }
        guard let previousFrame else { return }

        let deltaX = window.frame.origin.x - previousFrame.origin.x
        let deltaY = window.frame.origin.y - previousFrame.origin.y
        guard deltaX != 0 || deltaY != 0 else { return }

        isSyncing = true
        defer { isSyncing = false }

        if isHorizontal, let verticalWindow {
            let targetOrigin = NSPoint(
                x: verticalWindow.frame.origin.x + deltaX,
                y: verticalWindow.frame.origin.y + deltaY
            )
            verticalWindow.setFrameOrigin(targetOrigin)
            lastVerticalFrame = verticalWindow.frame
        } else if let horizontalWindow {
            let targetOrigin = NSPoint(
                x: horizontalWindow.frame.origin.x + deltaX,
                y: horizontalWindow.frame.origin.y + deltaY
            )
            horizontalWindow.setFrameOrigin(targetOrigin)
            lastHorizontalFrame = horizontalWindow.frame
        }
    }

    private func updateStoredFrame(for window: NSWindow, isHorizontal: Bool) {
        if isHorizontal {
            lastHorizontalFrame = window.frame
        } else {
            lastVerticalFrame = window.frame
        }
    }

    private func removeObservers() {
        let center = NotificationCenter.default
        observers.forEach { center.removeObserver($0) }
        observers.removeAll()
    }

    deinit {
        removeObservers()
    }
}
