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
    private let horizontalOverlayViewModel: OverlayViewModel
    private let rulerSettings: RulerSettingsViewModel
    private var keyDownObserver: NSObjectProtocol?
    private let dividerModel: DividerRangeModel<VerticalDividerHandle>

    /// Process-wide shared vertical overlay state used by the live app runtime.
    /// Access on the main actor when mutating from UI code.
    static let shared = OverlayVerticalViewModel()

    var topDividerY: CGFloat? {
        get { dividerModel.firstMarkerValue }
        set { dividerModel.firstMarkerValue = newValue }
    }

    var bottomDividerY: CGFloat? {
        get { dividerModel.secondMarkerValue }
        set { dividerModel.secondMarkerValue = newValue }
    }

    var selectedHandle: VerticalDividerHandle {
        get { dividerModel.selectedHandle }
        set { dividerModel.selectedHandle = newValue }
    }

    var snappedHandle: VerticalDividerHandle?

    var backingScale: CGFloat = 1.0
    var windowFrame: CGRect = .zero {
        didSet {
            guard windowFrame.height > 0 else { return }
            dividerModel.axisLength = windowFrame.height
        }
    }

    init(
        defaults: DefaultsStoring = UserDefaults.standard,
        horizontalOverlayViewModel: OverlayViewModel = .shared,
        rulerSettings: RulerSettingsViewModel = .shared
    ) {
        self.horizontalOverlayViewModel = horizontalOverlayViewModel
        self.rulerSettings = rulerSettings
        self.dividerModel = DividerRangeModel(
            defaults: defaults,
            firstMarkerKey: PersistenceKeys.topDividerY,
            secondMarkerKey: PersistenceKeys.bottomDividerY,
            selectedHandleKey: PersistenceKeys.verticalSelectedHandle,
            defaultSelectedHandle: .top
        )

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
        Int((dividerModel.markerDistance * backingScale).rounded())
    }

    func updateDividers(with rawY: CGFloat, axisLength: CGFloat, magnification: CGFloat, unitType: UnitTypes) {
        let boundedY = snappedValue(rawValue: rawY, axisLength: axisLength, magnification: magnification, unitType: unitType)
        let updatedMarker = dividerModel.updateDividers(with: boundedY, maxValue: axisLength)
        selectedHandle = updatedMarker == .first ? .top : .bottom
    }

    func boundedDividerValue(_ value: CGFloat, maxValue: CGFloat? = nil) -> CGFloat {
        dividerModel.boundedDividerValue(value, maxValue: maxValue)
    }

    func snappedValue(rawValue: CGFloat, axisLength: CGFloat, magnification: CGFloat, unitType: UnitTypes) -> CGFloat {
        let logicalValue = rawValue / max(magnification, 0.1)
        let boundedValue = boundedDividerValue(logicalValue, maxValue: axisLength)
        let snapSettings = rulerSettings.handleSnapConfiguration

        guard snapSettings.snapEnabled else {
            snappedHandle = nil
            return boundedValue
        }

        let tolerance = max(snapSettings.snapTolerancePoints, 0)
        var candidates: [CGFloat] = [0, axisLength]

        if snapSettings.snapToMajorTicks {
            let majorStep = unitType.tickConfiguration.majorEveryInPoints
            if majorStep > 0 {
                let majorTick = (boundedValue / majorStep).rounded() * majorStep
                candidates.append(majorTick)
            }
        }

        if let gridStep = snapSettings.snapGridStepPoints, gridStep > 0 {
            let gridTick = (boundedValue / gridStep).rounded() * gridStep
            candidates.append(gridTick)
        }

        let nearest = candidates
            .map { boundedDividerValue($0, maxValue: axisLength) }
            .min { abs($0 - boundedValue) < abs($1 - boundedValue) }

        guard let nearest else {
            snappedHandle = nil
            return boundedValue
        }

        if abs(nearest - boundedValue) <= tolerance {
            return nearest
        }

        snappedHandle = nil
        return boundedValue
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

        let bounded = boundedDividerValue(nextValue, maxValue: windowFrame.height)
        switch handle {
        case .top:
            topDividerY = bounded
        case .bottom:
            bottomDividerY = bounded
        }
    }
}
