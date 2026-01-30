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
    static let shared = MagnificationViewModel()

    var rulerFrame: CGRect = .zero
    var screen: NSScreen?
    var dancingAntsFrame: CGRect = .zero
    var isMagnifierVisible: Bool = false

    private init() {}
}
