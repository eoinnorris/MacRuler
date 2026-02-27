//
//  CrosshairReadoutFormatter.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-26.
//

import CoreGraphics

enum CrosshairReadoutFormatter {
    static func makeDeltaLabels(
        primaryCrosshairOffset: CGSize,
        secondaryCrosshairOffset: CGSize,
        unitType: UnitTypes,
        measurementScale: Double,
        magnification: CGFloat,
        showMeasurementScaleOverride: Bool
    ) -> [String] {
        let clampedMagnification = max(magnification, 0.1)
        let deltaPoints = CGSize(
            width: abs(secondaryCrosshairOffset.width - primaryCrosshairOffset.width) / clampedMagnification,
            height: abs(secondaryCrosshairOffset.height - primaryCrosshairOffset.height) / clampedMagnification
        )

        let deltaXComponents = ReadoutDisplayHelper.makeComponents(
            distancePoints: deltaPoints.width,
            unitType: unitType,
            measurementScale: measurementScale,
            magnification: magnification,
            showMeasurementScaleOverride: showMeasurementScaleOverride
        )
        let deltaYComponents = ReadoutDisplayHelper.makeComponents(
            distancePoints: deltaPoints.height,
            unitType: unitType,
            measurementScale: measurementScale,
            magnification: magnification,
            showMeasurementScaleOverride: showMeasurementScaleOverride
        )

        return ["ΔX: \(deltaXComponents.text)", "ΔY: \(deltaYComponents.text)"]
    }
}
