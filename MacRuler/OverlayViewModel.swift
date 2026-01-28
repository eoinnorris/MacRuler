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
}
