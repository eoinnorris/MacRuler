//
//  OverlayViewModel.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

@Observable
@MainActor
final class OverlayViewModel {
    private let defaults: DefaultsStoring
    private var keyDownObserver: NSObjectProtocol?

    /// Process-wide shared horizontal overlay state used by the live app runtime.
    /// Access on the main actor when mutating from UI code.

    var dividerX: CGFloat? {
        didSet {
            storeDividerValue(dividerX, forKey: PersistenceKeys.dividerX)
        }
    }

    var selectedPoints: DividerStep {
        didSet {
            defaults.set(selectedPoints.rawValue, forKey: PersistenceKeys.selectedPoints)
        }
    }

    var showDividerDance: Bool {
        didSet {
            defaults.set(showDividerDance, forKey: PersistenceKeys.showDividerDance)
        }
    }

    var backingScale: CGFloat = 1.0
    var windowFrame: CGRect = .zero {
        didSet {
            guard windowFrame.width > 0, let dividerX else { return }
            self.dividerX = boundedDividerValue(dividerX, maxValue: windowFrame.width)
        }
    }

    init(defaults: DefaultsStoring = UserDefaults.standard) {
        self.defaults = defaults

        let storedPoints = defaults.integer(forKey: PersistenceKeys.selectedPoints)
        self.selectedPoints = DividerStep(rawValue: storedPoints) ?? .one
        self.showDividerDance = defaults.bool(forKey: PersistenceKeys.showDividerDance)
        self.dividerX = Self.loadDividerValue(from: defaults, forKey: PersistenceKeys.dividerX)
        startObservingKeyInputs()
    }

    @MainActor
    deinit {
        if let keyDownObserver {
            NotificationCenter.default.removeObserver(keyDownObserver)
        }
    }

    var dividerDistancePixels: Int {
        guard let dividerX else { return 0 }
        return Int((dividerX * backingScale).rounded())
    }

    func updateDividers(with x: CGFloat, axisLength: CGFloat, magnification: CGFloat, unitType: UnitTypes) {
        let safeMagnification = max(magnification, 0.1)
        let rawX = x / safeMagnification
        dividerX = boundedDividerValue(rawX, maxValue: axisLength)
    }

    func boundedDividerValue(_ value: CGFloat, maxValue: CGFloat? = nil) -> CGFloat {
        let upperBound = maxValue ?? windowFrame.width
        guard upperBound > 0 else { return value }
        return min(max(value, 0), upperBound)
    }

    private static func loadDividerValue(from defaults: DefaultsStoring, forKey key: String) -> CGFloat? {
        guard defaults.object(forKey: key) != nil else { return nil }
        return CGFloat(defaults.double(forKey: key))
    }

    private func storeDividerValue(_ value: CGFloat?, forKey key: String) {
        if let value {
            defaults.set(Double(value), forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private func startObservingKeyInputs() {
        keyDownObserver = NotificationCenter.default.addObserver(
            forName: DividerKeyNotification.name,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let localSelf = self,
                let payload = DividerKeyNotification.payload(from: notification)
            else {
                return
            }

            Task { @MainActor in
                localSelf.handleDividerKeyNotification(direction: payload.direction,
                                                       isDouble: payload.isDouble)
            }
        }
    }

    @MainActor
    private func handleDividerKeyNotification(direction: DividerKeyDirection,
                                              isDouble: Bool) {
        switch direction {
        case .left, .right:
            break
        case .up, .down:
            return
        }

        guard let dividerX else { return }

        let pixelStep = selectedPoints.rawValue * (isDouble ? 2 : 1)
        let delta = CGFloat(pixelStep) / max(backingScale, 0.1)
        let nextValue: CGFloat = direction == .left ? dividerX - delta : dividerX + delta
        self.dividerX = boundedDividerValue(nextValue, maxValue: windowFrame.width)
    }
}
