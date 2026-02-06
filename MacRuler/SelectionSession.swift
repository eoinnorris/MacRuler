//
//  SelectionSession.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-06.
//

import Foundation
import CoreGraphics
import AppKit
import Observation

@Observable
final class SelectionSession: Identifiable {
    let id: UUID
    var selectionRectGlobal: CGRect
    var screen: NSScreen?
    var magnification: Double
    var showDancingAnts: Bool
    var showRulerOverlay: Bool
    var isWindowVisible: Bool

    init(
        id: UUID = UUID(),
        selectionRectGlobal: CGRect,
        screen: NSScreen?,
        magnification: Double = 1.0,
        showDancingAnts: Bool = true,
        showRulerOverlay: Bool = false,
        isWindowVisible: Bool = true
    ) {
        self.id = id
        self.selectionRectGlobal = selectionRectGlobal
        self.screen = screen
        self.magnification = magnification
        self.showDancingAnts = showDancingAnts
        self.showRulerOverlay = showRulerOverlay
        self.isWindowVisible = isWindowVisible
    }
}
