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
    private let rulerSettings: RulerSettingsViewModel
    private var keyDownObserver: NSObjectProtocol?

    /// Process-wide shared vertical overlay state used by the live app runtime.
    /// Access on the main actor when mutating from UI code.
    static let shared = OverlayVerticalViewModel()

    var topDividerY: CGFloat? {
        didSet {
            storeDividerValue(topDividerY, forKey: PersistenceKeys.topDividerY)
        }
    }

    var bottomDividerY: CGFloat? {
        didSet {
            storeDividerValue(bottomDividerY, forKey: PersistenceKeys.bottomDividerY)
        }
    }

    var selectedHandle: VerticalDividerHandle {
        didSet {
            defaults.set(selectedHandle.rawValue, forKey: PersistenceKeys.verticalSelectedHandle)
        }
    }

    var snappedHandle: VerticalDividerHandle?
    
    var backingScale: CGFloat = 1.0
    var windowFrame: CGRect = .zero {
        didSet {
            guard windowFrame.height > 0 else { return }
            let resetOutOfBounds = oldValue == .zero
            normalizeDividers(for: windowFrame.height, resetOutOfBounds: resetOutOfBounds)
        }
    }

    init(
        defaults: DefaultsStoring = UserDefaults.standard,
        horizontalOverlayViewModel: OverlayViewModel = .shared,
        rulerSettings: RulerSettingsViewModel = .shared
    ) {
        self.defaults = defaults
        self.horizontalOverlayViewModel = horizontalOverlayViewModel
        self.rulerSettings = rulerSettings

        if let storedHandle = defaults.string(forKey: PersistenceKeys.verticalSelectedHandle),
           let handle = VerticalDividerHandle(rawValue: storedHandle) {
            self.selectedHandle = handle
        } else {
            self.selectedHandle = .top
        }

        self.topDividerY = loadDividerValue(forKey: PersistenceKeys.topDividerY)
        self.bottomDividerY = loadDividerValue(forKey: PersistenceKeys.bottomDividerY)

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
        guard let topDividerY, let bottomDividerY else { return 0 }
        return Int((abs(bottomDividerY - topDividerY) * backingScale).rounded())
    }

    func updateDividers(with rawY: CGFloat, axisLength: CGFloat, magnification: CGFloat, unitType: UnitTypes) {
        
        if topDividerY == nil {
            topDividerY = rawY
            selectedHandle = .top
            return
        }

        if bottomDividerY == nil {
            if let topDividerY, rawY < topDividerY {
                bottomDividerY = topDividerY
                self.topDividerY = rawY
                selectedHandle = .top
            } else {
                bottomDividerY = rawY
                selectedHandle = .bottom
            }
            return
        }

        guard let topDividerY, let bottomDividerY else { return }

        if rawY <= topDividerY {
            self.topDividerY = rawY
            selectedHandle = .top
            return
        }

        if rawY >= bottomDividerY {
            self.bottomDividerY = rawY
            selectedHandle = .bottom
            return
        }

        let topDistance = abs(rawY - topDividerY)
        let bottomDistance = abs(bottomDividerY - rawY)
        if topDistance <= bottomDistance {
            self.topDividerY = rawY
            selectedHandle = .top
        } else {
            self.bottomDividerY = rawY
            selectedHandle = .bottom
        }
    }

    func boundedDividerValue(_ value: CGFloat, maxValue: CGFloat? = nil) -> CGFloat {
        let upperBound = maxValue ?? windowFrame.height
        guard upperBound > 0 else { return value }
        return min(max(value, 0), upperBound)
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

        let pixelStep = selectedPoints.rawValue * (isDouble ? 2 : 1)
        let delta = CGFloat(pixelStep) / max(backingScale, 0.1)

        switch selectedHandle {
        case .top:
            guard let topDividerY else { return }
            applyDelta(delta, direction: direction, to: topDividerY, handle: .top)
        case .bottom:
            guard let bottomDividerY else { return }
            applyDelta(delta, direction: direction, to: bottomDividerY, handle: .bottom)
        }
    }

    private func applyDelta(_ delta: CGFloat, direction: DividerKeyDirection, to currentValue: CGFloat, handle: VerticalDividerHandle) {
        let nextValue: CGFloat
        switch direction {
        case .up:
            nextValue = currentValue - delta
        case .down:
            nextValue = currentValue + delta
        case .left, .right:
            return
        }
       
        switch handle {
        case .top:
            topDividerY = nextValue
        case .bottom:
            bottomDividerY = nextValue
        }
    }

    private func normalizeDividers(for height: CGFloat, resetOutOfBounds: Bool) {
        guard let topDividerY, let bottomDividerY else { return }
        let minY: CGFloat = 0
        let maxY: CGFloat = height
        let isOutOfBounds = topDividerY < minY
            || bottomDividerY > maxY
            || topDividerY > maxY
            || bottomDividerY < minY
            || topDividerY > bottomDividerY

        if resetOutOfBounds && isOutOfBounds {
            let defaults = defaultDividerPositions(for: height)
            self.topDividerY = defaults.top
            self.bottomDividerY = defaults.bottom
            return
        }

        var clampedTop = min(max(topDividerY, minY), maxY)
        var clampedBottom = min(max(bottomDividerY, minY), maxY)

        if clampedTop > clampedBottom {
            let defaults = defaultDividerPositions(for: height)
            clampedTop = defaults.top
            clampedBottom = defaults.bottom
        }

        if clampedTop != topDividerY {
            self.topDividerY = clampedTop
        }

        if clampedBottom != bottomDividerY {
            self.bottomDividerY = clampedBottom
        }
    }

    private func defaultDividerPositions(for height: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        let top = height / 3.0
        let bottom = (height / 3.0) * 2.0
        return (min(max(top, 0), height), min(max(bottom, 0), height))
    }
}
