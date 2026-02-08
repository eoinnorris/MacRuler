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
    private let defaults: DefaultsStoring
    private var keyDownObserver: NSObjectProtocol?
    private let dividerModel: DividerRangeModel<DividerHandle>

    /// Process-wide shared horizontal overlay state used by the live app runtime.
    /// Access on the main actor when mutating from UI code.
    static let shared = OverlayViewModel()

    var leftDividerX: CGFloat? {
        get { dividerModel.firstMarkerValue }
        set { dividerModel.firstMarkerValue = newValue }
    }

    var rightDividerX: CGFloat? {
        get { dividerModel.secondMarkerValue }
        set { dividerModel.secondMarkerValue = newValue }
    }

    var selectedHandle: DividerHandle {
        get { dividerModel.selectedHandle }
        set { dividerModel.selectedHandle = newValue }
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
            guard windowFrame.width > 0 else { return }
            dividerModel.axisLength = windowFrame.width
        }
    }

    init(defaults: DefaultsStoring = UserDefaults.standard) {
        self.defaults = defaults
        self.dividerModel = DividerRangeModel(
            defaults: defaults,
            firstMarkerKey: PersistenceKeys.leftDividerX,
            secondMarkerKey: PersistenceKeys.rightDividerX,
            selectedHandleKey: PersistenceKeys.selectedHandle,
            defaultSelectedHandle: .left
        )

        let storedPoints = defaults.integer(forKey: PersistenceKeys.selectedPoints)
        self.selectedPoints = DividerStep(rawValue: storedPoints) ?? .one
        self.showDividerDance = defaults.bool(forKey: PersistenceKeys.showDividerDance)
        startObservingKeyInputs()
    }

    @MainActor
    deinit {
        if let keyDownObserver {
            NotificationCenter.default.removeObserver(keyDownObserver)
        }
    }

    var dividerDistancePixels: Int {
        Int((dividerModel.markerDistance * backingScale).rounded())
    }

    func updateDividers(with x: CGFloat, axisLength: CGFloat, magnification: CGFloat, unitType: UnitTypes) {
        let updatedMarker = dividerModel.updateDividers(with: x, maxValue: axisLength)
        selectedHandle = updatedMarker == .first ? .left : .right
    }

    func boundedDividerValue(_ value: CGFloat, maxValue: CGFloat? = nil) -> CGFloat {
        dividerModel.boundedDividerValue(value, maxValue: maxValue)
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

        let pixelStep = selectedPoints.rawValue * (isDouble ? 2 : 1)
        let delta = CGFloat(pixelStep) / max(backingScale, 0.1)

        switch selectedHandle {
        case .left:
            guard let leftDividerX else { return }
            applyDelta(delta, direction: direction, to: leftDividerX, handle: .left)
        case .right:
            guard let rightDividerX else { return }
            applyDelta(delta, direction: direction, to: rightDividerX, handle: .right)
        }
    }

    private func applyDelta(_ delta: CGFloat, direction: DividerKeyDirection, to currentValue: CGFloat, handle: DividerHandle) {
        let nextValue: CGFloat
        switch direction {
        case .left:
            nextValue = currentValue - delta
        case .right:
            nextValue = currentValue + delta
        case .up, .down:
            return
        }

        let bounded = boundedDividerValue(nextValue, maxValue: windowFrame.width)
        switch handle {
        case .left:
            leftDividerX = bounded
        case .right:
            rightDividerX = bounded
        }
    }
}
