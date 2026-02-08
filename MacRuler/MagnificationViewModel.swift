//
//  MagnificationViewModel.swift
//  MacRuler
//
//  Created by Eoin Kortext on 29/01/2026.
//

import CoreGraphics
import Observation
import AppKit

@Observable
final class MagnificationViewModel {
    /// Process-wide shared magnification state used by the live app runtime.
    /// Access on the main actor when mutating from UI code.
    static let shared = MagnificationViewModel()

    var rulerFrame: CGRect = .zero
    var rulerWindowFrame: CGRect = .zero
    var screen: NSScreen?
    var dancingAntsFrame: CGRect = .zero
    var isMagnifierVisible: Bool = true
    var magnification: Double = 1.0

    init() {}
}
