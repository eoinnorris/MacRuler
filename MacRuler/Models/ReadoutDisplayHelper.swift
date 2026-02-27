//
//  ReadoutDisplayHelper.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-15.
//

import CoreGraphics
import Foundation

struct ReadoutDisplayComponents {
    let displayValue: String
    let unitSymbol: String
    let magnificationLabel: String
    let measurementScaleLabel: String?

    var text: String {
        var components = ["\(displayValue) \(unitSymbol)", magnificationLabel]
        if let measurementScaleLabel {
            components.append(measurementScaleLabel)
        }
        return components.joined(separator: " • ")
    }
}


enum ReadoutDisplayHelper {
    static func makePointDeltaReadout(delta: CGSize) -> String {
        "Δ: \(delta.width.formatted(.number.precision(.fractionLength(1)))) pt × \(delta.height.formatted(.number.precision(.fractionLength(1)))) pt"
    }

    static func makeComponents(
        distancePoints: CGFloat,
        unitType: UnitTypes,
        measurementScale: Double,
        magnification: CGFloat,
        showMeasurementScaleOverride: Bool
    ) -> ReadoutDisplayComponents {
        let scaleLabel = showMeasurementScaleOverride
            ? "Scale \(measurementScale.formatted(.number.precision(.fractionLength(1))))x"
            : nil

        return ReadoutDisplayComponents(
            displayValue: unitType.formattedDistance(points: distancePoints, screenScale: measurementScale),
            unitSymbol: unitType.unitSymbol,
            magnificationLabel: MagnificationViewModel.formatLabel(magnification),
            measurementScaleLabel: scaleLabel
        )
    }
}
