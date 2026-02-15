//
//  OverlayVerticalViewModel.swift
//  MacRuler
//
//  Created by OpenAI Codex on 28/01/2026.
//

import SwiftUI

@Observable
final class OverlayVerticalViewModel {
    private let defaults: DefaultsStoring
    private let horizontalOverlayViewModel: OverlayViewModel
    private var keyDownObserver: NSObjectProtocol?

    /// Process-wide shared vertical overlay state used by the live app runtime.
    /// Access on the main actor when mutating from UI code.

    var dividerY: CGFloat? {
        didSet {
            storeDividerValue(dividerY, forKey: PersistenceKeys.dividerY)
        }
    }

    var backingScale: CGFloat = 1.0
    var windowFrame: CGRect = .zero {
        didSet {
            guard windowFrame.height > 0, let dividerY else { return }
            self.dividerY = boundedDividerValue(dividerY, maxValue: windowFrame.height)
        }
    }

    init(
        defaults: DefaultsStoring = UserDefaults.standard,
        horizontalOverlayViewModel: OverlayViewModel,
        rulerSettings: RulerSettingsViewModel = .shared
    ) {
        self.defaults = defaults
        self.horizontalOverlayViewModel = horizontalOverlayViewModel
        _ = rulerSettings
        self.dividerY = Self.loadDividerValue(from: defaults, forKey: PersistenceKeys.dividerY)

        startObservingKeyInputs()
    }

    @MainActor
    deinit {
        if let keyDownObserver {
            NotificationCenter.default.removeObserver(keyDownObserver)
        }
    }

    var selectedPoints: DividerStep {
        horizontalOverlayViewModel.selectedPoints
    }

    var dividerDistancePixels: Int {
        guard let dividerY else { return 0 }
        return Int((dividerY * backingScale).rounded())
    }

    func updateDividers(with rawY: CGFloat, axisLength: CGFloat, magnification: CGFloat, unitType: UnitTypes) {
        let safeMagnification = max(magnification, 0.1)
        let normalizedY = rawY / safeMagnification
        dividerY = boundedDividerValue(normalizedY, maxValue: axisLength)
    }

    func boundedDividerValue(_ value: CGFloat, maxValue: CGFloat? = nil) -> CGFloat {
        let upperBound = maxValue ?? windowFrame.height
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
    private func handleDividerKeyNotification(direction: DividerKeyDirection, isDouble: Bool) {
        switch direction {
        case .up, .down:
            break
        case .left, .right:
            return
        }

        guard let dividerY else { return }

        let pixelStep = selectedPoints.rawValue * (isDouble ? 2 : 1)
        let delta = CGFloat(pixelStep) / max(backingScale, 0.1)
        let nextValue: CGFloat = direction == .up ? dividerY - delta : dividerY + delta
        self.dividerY = boundedDividerValue(nextValue, maxValue: windowFrame.height)
    }
}
