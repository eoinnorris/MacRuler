//
//  MagnifierWindowDelegate.swift
//  MacRuler
//
//  Created by Eoin Kortext on 05/02/2026.
//


import Swift
import SwiftUI

final class MagnifierWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
