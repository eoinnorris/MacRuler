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

enum MagnifierReadoutMode: Equatable {
    case crosshairOnly
    case crosshairPlusRulers
}

@Observable
@MainActor
final class SelectionSession: Identifiable {
    let id: UUID
    var selectionRectGlobal: CGRect
    var selectionRectScreen: CGRect
    var screen: NSScreen?
    var magnification: Double
    var showSelection: Bool
    var showRulerOverlay: Bool
    var showHorizontalRuler: Bool
    var showVerticalRuler: Bool
    var isWindowVisible: Bool

    var magnifierReadoutMode: MagnifierReadoutMode {
        if showHorizontalRuler || showVerticalRuler {
            .crosshairPlusRulers
        } else {
            .crosshairOnly
        }
    }

    init(
        id: UUID = UUID(),
        selectionRectScreen: CGRect,
        selectionRectGlobal: CGRect,
        screen: NSScreen?,
        magnification: Double = 1.0,
        showSelection: Bool = false,
        showRulerOverlay: Bool = false,
        showHorizontalRuler: Bool = false,
        showVerticalRuler: Bool = false,
        isWindowVisible: Bool = true
    ) {
        self.id = id
        self.selectionRectGlobal = selectionRectGlobal
        self.screen = screen
        self.magnification = magnification
        self.showSelection = showSelection
        self.showRulerOverlay = showRulerOverlay
        self.showHorizontalRuler = showHorizontalRuler
        self.showVerticalRuler = showVerticalRuler
        self.isWindowVisible = isWindowVisible
        self.selectionRectScreen = selectionRectScreen
    }
}
