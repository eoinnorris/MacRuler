//
//  OverlayVerticalViewModel.swift
//  MacRuler
//
//  Created by OpenAI Codex on 28/01/2026.
//

import SwiftUI

enum VerticalDividerHandle: String, CaseIterable, Identifiable {
    case top
    case bottom

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .top:
            return "Select top handle"
        case .bottom:
            return "Select bottom handle"
        }
    }
}

@Observable
final class OverlayVerticalViewModel {
    private let defaults: UserDefaults
    private var keyDownObserver: NSObjectProtocol?

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
    
    var topHandleSelected: Bool {
        get { selectedHandle == .top }
        set { selectedHandle = .top  }
    }
    
    var bottomHandleSelected: Bool {
        get { selectedHandle == .bottom }
        set { selectedHandle = .bottom  }
    }

    var backingScale: CGFloat = 1.0
    var windowFrame: CGRect = .zero {
        didSet {
            guard windowFrame.height > 0 else { return }
            let resetOutOfBounds = oldValue == .zero
            normalizeDividers(for: windowFrame.height, resetOutOfBounds: resetOutOfBounds)
        }
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

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
        OverlayViewModel.shared.selectedPoints
    }

    func updateDividers(with y: CGFloat) {
        let boundedY = boundedDividerValue(y)
        if topDividerY == nil {
            topDividerY = boundedY
            selectedHandle = .top
            return
        }

        if bottomDividerY == nil {
            if let topDividerY, boundedY < topDividerY {
                bottomDividerY = topDividerY
                self.topDividerY = boundedY
                selectedHandle = .top
            } else {
                bottomDividerY = boundedY
                selectedHandle = .bottom
            }
            return
        }

        guard let topDividerY, let bottomDividerY else { return }

        if boundedY <= topDividerY {
            self.topDividerY = boundedY
            selectedHandle = .top
            return
        }

        if boundedY >= bottomDividerY {
            self.bottomDividerY = boundedY
            selectedHandle = .bottom
            return
        }

        let topDistance = abs(boundedY - topDividerY)
        let bottomDistance = abs(bottomDividerY - boundedY)
        if topDistance <= bottomDistance {
            self.topDividerY = boundedY
            selectedHandle = .top
        } else {
            self.bottomDividerY = boundedY
            selectedHandle = .bottom
        }
    }

    func boundedDividerValue(_ value: CGFloat) -> CGFloat {
        guard windowFrame.height > 0 else { return value }
        return min(max(value, 0), windowFrame.height)
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
        let directionKey = DividerKeyNotification.directionKey
        let isDoubleKey = DividerKeyNotification.isDoubleKey

        keyDownObserver = NotificationCenter.default.addObserver(
            forName: DividerKeyNotification.name,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let directionRaw = notification.userInfo?[directionKey] as? String ?? ""
            let isDouble = notification.userInfo?[isDoubleKey] as? Bool ?? false

            Task { @MainActor in
                guard
                    let direction = DividerKeyDirection(rawValue: directionRaw)
                else {
                    return
                }

                self?.handleDividerKeyNotification(direction: direction, isDouble: isDouble)
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
            applyDelta(delta, direction: direction, to: topDividerY, setter: { self.topDividerY = $0 })
        case .bottom:
            guard let bottomDividerY else { return }
            applyDelta(delta, direction: direction, to: bottomDividerY, setter: { self.bottomDividerY = $0 })
        }
    }

    private func applyDelta(_ delta: CGFloat, direction: DividerKeyDirection, to currentValue: CGFloat, setter: (CGFloat) -> Void) {
        let nextValue: CGFloat
        switch direction {
        case .up:
            nextValue = currentValue - delta
        case .down:
            nextValue = currentValue + delta
        case .left, .right:
            return
        }
        setter(boundedDividerValue(nextValue))
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
