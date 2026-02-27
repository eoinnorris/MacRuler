import CoreGraphics
import Observation

@Observable
@MainActor
final class MagnifierCrosshairViewModel {
    static let defaultSecondaryOffset = CGSize(width: 24, height: 24)

    var primaryOffset: CGSize
    var secondaryOffset: CGSize

    init(
        primaryOffset: CGSize = .zero,
        secondaryOffset: CGSize
    ) {
        self.primaryOffset = primaryOffset
        self.secondaryOffset = secondaryOffset
    }

    func resetAllOffsets() {
        primaryOffset = .zero
        secondaryOffset = Self.defaultSecondaryOffset
    }

    func resetSecondaryOffset() {
        secondaryOffset = Self.defaultSecondaryOffset
    }

    func deltaPoints(magnification: CGFloat) -> CGSize {
        let safeMagnification = max(magnification, 0.1)
        return CGSize(
            width: abs(secondaryOffset.width - primaryOffset.width) / safeMagnification,
            height: abs(secondaryOffset.height - primaryOffset.height) / safeMagnification
        )
    }

    func clampedOffset(_ offset: CGSize, in viewportSize: CGSize) -> CGSize {
        let halfWidth = viewportSize.width / 2
        let halfHeight = viewportSize.height / 2

        return CGSize(
            width: min(max(offset.width, -halfWidth), halfWidth),
            height: min(max(offset.height, -halfHeight), halfHeight)
        )
    }

    func readoutComposition(
        mode: MagnifierReadoutMode,
        unitType: UnitTypes,
        magnification: Double,
        showCrosshair: Bool,
        showSecondaryCrosshair: Bool,
        horizontalDistancePoints: CGFloat?,
        horizontalDisplayScale: Double,
        verticalDistancePoints: CGFloat?,
        verticalDisplayScale: Double,
        measurementScaleProvider: (Double) -> Double,
        showMeasurementScaleOverride: Bool
    ) -> MagnifierReadoutComposition {
        MagnifierReadoutComposition.compose(
            mode: mode,
            unitType: unitType,
            magnification: magnification,
            showCrosshair: showCrosshair,
            showSecondaryCrosshair: showSecondaryCrosshair,
            primaryCrosshairOffset: primaryOffset,
            secondaryCrosshairOffset: secondaryOffset,
            horizontalDistancePoints: horizontalDistancePoints,
            horizontalDisplayScale: horizontalDisplayScale,
            verticalDistancePoints: verticalDistancePoints,
            verticalDisplayScale: verticalDisplayScale,
            measurementScaleProvider: measurementScaleProvider,
            showMeasurementScaleOverride: showMeasurementScaleOverride
        )
    }

    func formattedDeltaReadouts(
        unitType: UnitTypes,
        measurementScale: Double,
        magnification: CGFloat,
        showMeasurementScaleOverride: Bool
    ) -> [String] {
        CrosshairReadoutFormatter.makeDeltaLabels(
            primaryCrosshairOffset: primaryOffset,
            secondaryCrosshairOffset: secondaryOffset,
            unitType: unitType,
            measurementScale: measurementScale,
            magnification: magnification,
            showMeasurementScaleOverride: showMeasurementScaleOverride
        )
    }
}
