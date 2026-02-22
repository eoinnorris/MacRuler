//
//  DividerRangeModel.swift
//  MacRuler
//
//  Created by OpenAI Codex on 08/02/2026.
//

import SwiftUI

@Observable
@MainActor
final class DividerRangeModel<Handle>
where Handle: RawRepresentable, Handle.RawValue == String {
    enum UpdatedMarker {
        case first
        case second
    }

    private let defaults: DefaultsStoring
    private let firstMarkerKey: String
    private let secondMarkerKey: String
    private let selectedHandleKey: String

    var firstMarkerValue: CGFloat? {
        didSet {
            storeDividerValue(firstMarkerValue, forKey: firstMarkerKey)
        }
    }

    var secondMarkerValue: CGFloat? {
        didSet {
            storeDividerValue(secondMarkerValue, forKey: secondMarkerKey)
        }
    }

    var selectedHandle: Handle {
        didSet {
            defaults.set(selectedHandle.rawValue, forKey: selectedHandleKey)
        }
    }

    var axisLength: CGFloat = 0 {
        didSet {
            guard axisLength > 0 else { return }
            normalizeDividers(for: axisLength, resetOutOfBounds: oldValue == 0)
        }
    }

    init(
        defaults: DefaultsStoring,
        firstMarkerKey: String,
        secondMarkerKey: String,
        selectedHandleKey: String,
        defaultSelectedHandle: Handle
    ) {
        self.defaults = defaults
        self.firstMarkerKey = firstMarkerKey
        self.secondMarkerKey = secondMarkerKey
        self.selectedHandleKey = selectedHandleKey

        if let storedHandle = defaults.string(forKey: selectedHandleKey),
           let handle = Handle(rawValue: storedHandle) {
            self.selectedHandle = handle
        } else {
            self.selectedHandle = defaultSelectedHandle
        }

        self.firstMarkerValue = loadDividerValue(forKey: firstMarkerKey)
        self.secondMarkerValue = loadDividerValue(forKey: secondMarkerKey)
    }

    var markerDistance: CGFloat {
        guard let firstMarkerValue, let secondMarkerValue else { return 0 }
        return abs(secondMarkerValue - firstMarkerValue)
    }

    func boundedDividerValue(_ value: CGFloat, maxValue: CGFloat? = nil) -> CGFloat {
        let upperBound = maxValue ?? axisLength
        guard upperBound > 0 else { return value }
        return min(max(value, 0), upperBound)
    }

    @discardableResult
    func updateDividers(with value: CGFloat, maxValue: CGFloat? = nil) -> UpdatedMarker {
        let boundedValue = boundedDividerValue(value, maxValue: maxValue)

        if firstMarkerValue == nil {
            firstMarkerValue = boundedValue
            return .first
        }

        if secondMarkerValue == nil {
            if let firstMarkerValue, boundedValue < firstMarkerValue {
                secondMarkerValue = firstMarkerValue
                self.firstMarkerValue = boundedValue
                return .first
            }

            secondMarkerValue = boundedValue
            return .second
        }

        guard let firstMarkerValue, let secondMarkerValue else {
            return .first
        }

        if boundedValue <= firstMarkerValue {
            self.firstMarkerValue = boundedValue
            return .first
        }

        if boundedValue >= secondMarkerValue {
            self.secondMarkerValue = boundedValue
            return .second
        }

        if abs(boundedValue - firstMarkerValue) <= abs(secondMarkerValue - boundedValue) {
            self.firstMarkerValue = boundedValue
            return .first
        }

        self.secondMarkerValue = boundedValue
        return .second
    }

    func normalize(resetOutOfBounds: Bool = false) {
        normalizeDividers(for: axisLength, resetOutOfBounds: resetOutOfBounds)
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

    private func normalizeDividers(for axisLength: CGFloat, resetOutOfBounds: Bool) {
        guard axisLength > 0 else { return }
        guard let firstMarkerValue, let secondMarkerValue else { return }

        let minValue: CGFloat = 0
        let maxValue: CGFloat = axisLength
        let isOutOfBounds = firstMarkerValue < minValue
            || secondMarkerValue > maxValue
            || firstMarkerValue > maxValue
            || secondMarkerValue < minValue
            || firstMarkerValue > secondMarkerValue

        if resetOutOfBounds && isOutOfBounds {
            let defaults = defaultDividerPositions(for: axisLength)
            self.firstMarkerValue = defaults.first
            self.secondMarkerValue = defaults.second
            return
        }

        var clampedFirst = min(max(firstMarkerValue, minValue), maxValue)
        var clampedSecond = min(max(secondMarkerValue, minValue), maxValue)

        if clampedFirst > clampedSecond {
            let defaults = defaultDividerPositions(for: axisLength)
            clampedFirst = defaults.first
            clampedSecond = defaults.second
        }

        if clampedFirst != firstMarkerValue {
            self.firstMarkerValue = clampedFirst
        }

        if clampedSecond != secondMarkerValue {
            self.secondMarkerValue = clampedSecond
        }
    }

    private func defaultDividerPositions(for axisLength: CGFloat) -> (first: CGFloat, second: CGFloat) {
        let first = axisLength / 3.0
        let second = (axisLength / 3.0) * 2.0
        return (
            min(max(first, 0), axisLength),
            min(max(second, 0), axisLength)
        )
    }
}
