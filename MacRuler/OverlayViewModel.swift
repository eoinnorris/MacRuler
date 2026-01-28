//
//  OverlayViewModel.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

@Observable
final class OverlayViewModel {
    private let defaults: UserDefaults
    private var keyDownObserver: NSObjectProtocol?

    
    
    var leftDividerX: CGFloat? {
        didSet {
            storeDividerValue(leftDividerX, forKey: PersistenceKeys.leftDividerX)
        }
    }
    var rightDividerX: CGFloat? {
        didSet {
            storeDividerValue(rightDividerX, forKey: PersistenceKeys.rightDividerX)
        }
    }
    var backingScale: CGFloat = 1.0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.leftDividerX = loadDividerValue(forKey: PersistenceKeys.leftDividerX)
        self.rightDividerX = loadDividerValue(forKey: PersistenceKeys.rightDividerX)
        startObservingKeyInputs()
    }

    deinit {
        if let keyDownObserver {
            NotificationCenter.default.removeObserver(keyDownObserver)
        }
    }

    var dividerDistancePixels: Int {
        guard let leftDividerX, let rightDividerX else { return 0 }
        return Int((abs(rightDividerX - leftDividerX) * backingScale).rounded())
    }
    
    func updateDividers(with x: CGFloat) {
        if leftDividerX == nil {
            leftDividerX = x
            return
        }

        if rightDividerX == nil {
            if let leftDividerX, x < leftDividerX {
                rightDividerX = leftDividerX
                self.leftDividerX = x
            } else {
                rightDividerX = x
            }
            return
        }

        guard let leftDividerX, let rightDividerX else { return }

        if x <= leftDividerX {
            self.leftDividerX = x
            return
        }

        if x >= rightDividerX {
            self.rightDividerX = x
            return
        }

        let leftDistance = abs(x - leftDividerX)
        let rightDistance = abs(rightDividerX - x)
        if leftDistance <= rightDistance {
            self.leftDividerX = x
        } else {
            self.rightDividerX = x
        }
    }

    private func loadDividerValue(forKey key: String) -> CGFloat? {
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
            self?.handleDividerKeyNotification(notification)
        }
    }

    private func handleDividerKeyNotification(_ notification: Notification) {
        guard
            let directionRaw = notification.userInfo?[DividerKeyNotification.directionKey] as? String,
            let direction = DividerKeyDirection(rawValue: directionRaw)
        else {
            return
        }

        let isDouble = notification.userInfo?[DividerKeyNotification.isDoubleKey] as? Bool ?? false
        let pixelStep = isDouble ? 10 : 1
        let delta = CGFloat(pixelStep) / max(backingScale, 0.1)

        guard let leftDividerX else { return }
        applyDelta(delta, direction: direction, to: leftDividerX, setter: { self.leftDividerX = $0 })
    }

    private func applyDelta(_ delta: CGFloat, direction: DividerKeyDirection, to currentValue: CGFloat, setter: (CGFloat) -> Void) {
        switch direction {
        case .left:
            setter(currentValue - delta)
        case .right:
            setter(currentValue + delta)
        }
    }
}
