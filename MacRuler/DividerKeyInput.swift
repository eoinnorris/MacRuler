//
//  DividerKeyInput.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import AppKit
import SwiftUI

enum DividerKeyDirection: String {
    case left
    case right
}

enum DividerKeyNotification {
    static let name = Notification.Name("DividerKeyNotification")
    static let directionKey = "direction"
    static let isDoubleKey = "isDouble"
}

struct DividerKeyCaptureView: NSViewRepresentable {
    func makeNSView(context: Context) -> DividerKeyCaptureNSView {
        let view = DividerKeyCaptureNSView()
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: DividerKeyCaptureNSView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

final class DividerKeyCaptureNSView: NSView {
    private let doubleTapThreshold: TimeInterval = 0.25
    private var lastKeyDownTimes: [DividerKeyDirection: TimeInterval] = [:]

    override var acceptsFirstResponder: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard let direction = keyDirection(from: event) else {
            super.keyDown(with: event)
            return
        }

        let now = event.timestamp
        let isDouble = (now - (lastKeyDownTimes[direction] ?? 0)) < doubleTapThreshold
        lastKeyDownTimes[direction] = now

        NotificationCenter.default.post(
            name: DividerKeyNotification.name,
            object: nil,
            userInfo: [
                DividerKeyNotification.directionKey: direction.rawValue,
                DividerKeyNotification.isDoubleKey: isDouble
            ]
        )
    }

    private func keyDirection(from event: NSEvent) -> DividerKeyDirection? {
        switch event.keyCode {
        case 123:
            return .left
        case 124:
            return .right
        default:
            return nil
        }
    }
}
