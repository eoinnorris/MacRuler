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
    static let minimumMagnification = 1.0
    static let maximumMagnification = 10.0
    static let magnificationStep = 0.2

    var rulerFrame: CGRect = .zero
    var rulerWindowFrame: CGRect = .zero
    var screen: NSScreen?
    var dancingAntsFrame: CGRect = .zero
    var isMagnifierVisible: Bool = true
    var magnification: Double = 1.0

    func clamp(_ value: Double) -> Double {
        min(max(value, Self.minimumMagnification), Self.maximumMagnification)
    }

    func normalizedMagnification(_ value: Double) -> Double {
        let clampedValue = clamp(value)
        let steppedValue = (clampedValue / Self.magnificationStep).rounded() * Self.magnificationStep
        return clamp((steppedValue * 10).rounded() / 10)
    }

    func increaseMagnification() -> Double {
        normalizedMagnification(magnification + Self.magnificationStep)
    }

    func decreaseMagnification() -> Double {
        normalizedMagnification(magnification - Self.magnificationStep)
    }

    static func formatLabel(_ magnification: Double) -> String {
        let roundedValue = magnification.rounded()
        if abs(magnification - roundedValue) < 0.0001 {
            return "\(Int(roundedValue)) x"
        }

        return String(format: "%.1f x", magnification)
    }

    init() {}
}
