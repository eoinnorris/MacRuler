import Foundation
import CoreGraphics

struct MagnifierReadoutComposition {
    let primaryReadouts: [String]
    let secondaryReadouts: [String]

    static func compose(
        mode: MagnifierReadoutMode,
        unitType: UnitTypes,
        magnification: Double,
        sourceDisplayScale: Double,
        showCrosshair: Bool,
        showSecondaryCrosshair: Bool,
        primaryCrosshairOffset: CGSize,
        secondaryCrosshairOffset: CGSize,
        horizontalDistancePoints: CGFloat?,
        horizontalDisplayScale: Double,
        verticalDistancePoints: CGFloat?,
        verticalDisplayScale: Double,
        measurementScaleProvider: (Double) -> Double,
        showMeasurementScaleOverride: Bool
    ) -> MagnifierReadoutComposition {
        var primaryReadouts: [String] = []
        var secondaryReadouts: [String] = []

        if showCrosshair && showSecondaryCrosshair {
            let safeMagnification = max(magnification, 0.1)
            let deltaX = abs(secondaryCrosshairOffset.width - primaryCrosshairOffset.width) / safeMagnification
            let deltaY = abs(secondaryCrosshairOffset.height - primaryCrosshairOffset.height) / safeMagnification
            let measurementScale = measurementScaleProvider(sourceDisplayScale)
            let unitSymbol = unitType.unitSymbol
            let deltaXLabel = unitType.formattedDistance(points: deltaX, screenScale: measurementScale)
            let deltaYLabel = unitType.formattedDistance(points: deltaY, screenScale: measurementScale)
            primaryReadouts.append(
                "Δ: \(deltaXLabel) \(unitSymbol) × \(deltaYLabel) \(unitSymbol)"
            )
        }

        guard mode == .crosshairPlusRulers else {
            return MagnifierReadoutComposition(primaryReadouts: primaryReadouts, secondaryReadouts: secondaryReadouts)
        }

        if let horizontalDistancePoints {
            let horizontalComponents = ReadoutDisplayHelper.makeComponents(
                distancePoints: horizontalDistancePoints,
                unitType: unitType,
                measurementScale: measurementScaleProvider(horizontalDisplayScale),
                magnification: magnification,
                showMeasurementScaleOverride: showMeasurementScaleOverride
            )
            secondaryReadouts.append("H:\(horizontalComponents.text)")
        }

        if let verticalDistancePoints {
            let verticalComponents = ReadoutDisplayHelper.makeComponents(
                distancePoints: verticalDistancePoints,
                unitType: unitType,
                measurementScale: measurementScaleProvider(verticalDisplayScale),
                magnification: magnification,
                showMeasurementScaleOverride: showMeasurementScaleOverride
            )
            secondaryReadouts.append("V:\(verticalComponents.text)")
        }

        return MagnifierReadoutComposition(primaryReadouts: primaryReadouts, secondaryReadouts: secondaryReadouts)
    }
}
