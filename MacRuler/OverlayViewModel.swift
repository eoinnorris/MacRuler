//
//  OverlayViewModel.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

enum DividerHandle: String, CaseIterable, Identifiable {
    case left
    case right

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .left:
            return "Select left handle"
        case .right:
            return "Select right handle"
        }
    }
}

enum DividerStep: Int, CaseIterable, Identifiable {
    case one = 1
    case five = 5
    case ten = 10

    var id: Int { rawValue }
    var displayName: String {
        "\(rawValue)px"
    }
}

@Observable
final class OverlayViewModel {
    private let defaults: UserDefaults
    private var keyDownObserver: NSObjectProtocol?

    static let shared = OverlayViewModel()
    
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
    var selectedHandle: DividerHandle {
        didSet {
            defaults.set(selectedHandle.rawValue, forKey: PersistenceKeys.selectedHandle)
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
    
    var rightHandleSelected: Bool {
        get { selectedHandle == .right }
        set { selectedHandle = .right }
    }
    
    var leftHandleSelected: Bool {
        get { selectedHandle == .left }
        set { selectedHandle =  .left }
    }
    
    var backingScale: CGFloat = 1.0
    var windowFrame: CGRect = .zero {
        didSet {
            guard windowFrame.width > 0 else { return }
            let resetOutOfBounds = oldValue == .zero
            normalizeDividers(for: windowFrame.width, resetOutOfBounds: resetOutOfBounds)
        }
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
      
        if let storedHandle = defaults.string(forKey: PersistenceKeys.selectedHandle),
           let handle = DividerHandle(rawValue: storedHandle) {
            self.selectedHandle = handle
        } else {
            self.selectedHandle = .left
        }
        let storedPoints = defaults.integer(forKey: PersistenceKeys.selectedPoints)
        self.selectedPoints = DividerStep(rawValue: storedPoints) ?? .one
        self.showDividerDance = defaults.bool(forKey: PersistenceKeys.showDividerDance)
        startObservingKeyInputs()
        
        self.leftDividerX = loadDividerValue(forKey: PersistenceKeys.leftDividerX)
        self.rightDividerX = loadDividerValue(forKey: PersistenceKeys.rightDividerX)
    }

    @MainActor
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
        let boundedX = boundedDividerValue(x)
        if leftDividerX == nil {
            leftDividerX = boundedX
            return
        }

        if rightDividerX == nil {
            if let leftDividerX, boundedX < leftDividerX {
                rightDividerX = leftDividerX
                self.leftDividerX = boundedX
            } else {
                rightDividerX = boundedX
            }
            return
        }

        guard let leftDividerX, let rightDividerX else { return }

        if boundedX <= leftDividerX {
            self.leftDividerX = boundedX
            return
        }

        if boundedX >= rightDividerX {
            self.rightDividerX = boundedX
            return
        }

        let leftDistance = abs(boundedX - leftDividerX)
        let rightDistance = abs(rightDividerX - boundedX)
        if leftDistance <= rightDistance {
            self.leftDividerX = boundedX
        } else {
            self.rightDividerX = boundedX
        }
    }

    func boundedDividerValue(_ value: CGFloat) -> CGFloat {
        guard windowFrame.width > 0 else { return value }
        return min(max(value, 0), windowFrame.width)
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

                self?.handleDividerKeyNotification(directionRow: directionRaw,
                                                   direction: direction,
                                                   isDouble: isDouble)
            }
        }
    }

    @MainActor
    private func handleDividerKeyNotification(directionRow:String,
                                              direction: DividerKeyDirection,
                                              isDouble: Bool) {
        switch direction {
        case .left, .right:
            break
        case .up, .down:
            return
        }

        let pixelStep = selectedPoints.rawValue * (isDouble ? 2 : 1)
        let delta = CGFloat(pixelStep) / max(backingScale, 0.1)

        switch selectedHandle {
        case .left:
            guard let leftDividerX else { return }
            applyDelta(delta, direction: direction, to: leftDividerX, setter: { self.leftDividerX = $0 })
        case .right:
            guard let rightDividerX else { return }
            applyDelta(delta, direction: direction, to: rightDividerX, setter: { self.rightDividerX = $0 })
        }
    }

    private func applyDelta(_ delta: CGFloat, direction: DividerKeyDirection, to currentValue: CGFloat, setter: (CGFloat) -> Void) {
        let nextValue: CGFloat
        switch direction {
        case .left:
            nextValue = currentValue - delta
        case .right:
            nextValue = currentValue + delta
        case .up, .down:
            return
        }
        setter(boundedDividerValue(nextValue))
    }

    private func normalizeDividers(for width: CGFloat, resetOutOfBounds: Bool) {
        guard let leftDividerX, let rightDividerX else { return }
        let minX: CGFloat = 0
        let maxX: CGFloat = width
        let isOutOfBounds = leftDividerX < minX
            || rightDividerX > maxX
            || leftDividerX > maxX
            || rightDividerX < minX
            || leftDividerX > rightDividerX

        if resetOutOfBounds && isOutOfBounds {
            let defaults = defaultDividerPositions(for: width)
            self.leftDividerX = defaults.left
            self.rightDividerX = defaults.right
            return
        }

        var clampedLeft = min(max(leftDividerX, minX), maxX)
        var clampedRight = min(max(rightDividerX, minX), maxX)

        if clampedLeft > clampedRight {
            let defaults = defaultDividerPositions(for: width)
            clampedLeft = defaults.left
            clampedRight = defaults.right
        }

        if clampedLeft != leftDividerX {
            self.leftDividerX = clampedLeft
        }

        if clampedRight != rightDividerX {
            self.rightDividerX = clampedRight
        }
    }

    private func defaultDividerPositions(for width: CGFloat) -> (left: CGFloat, right: CGFloat) {
        let left = width / 3.0
        let right = (width / 3.0) * 2.0
        return (min(max(left, 0), width), min(max(right, 0), width))
    }
}
