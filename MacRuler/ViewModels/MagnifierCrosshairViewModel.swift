import CoreGraphics
import Observation

@Observable
@MainActor
final class MagnifierCrosshairViewModel {
    static let secondaryCrosshairDefaultOffset = CGSize(width: 24, height: 24)

    var primaryCrosshairOffset: CGSize = .zero
    var secondaryCrosshairOffset: CGSize = Self.secondaryCrosshairDefaultOffset

    func resetOffsets() {
        primaryCrosshairOffset = .zero
        secondaryCrosshairOffset = Self.secondaryCrosshairDefaultOffset
    }

    func resetSecondaryOffset() {
        secondaryCrosshairOffset = Self.secondaryCrosshairDefaultOffset
    }

    func clampedOffset(_ offset: CGSize, viewportSize: CGSize) -> CGSize {
        let halfWidth = viewportSize.width / 2
        let halfHeight = viewportSize.height / 2

        return CGSize(
            width: min(max(offset.width, -halfWidth), halfWidth),
            height: min(max(offset.height, -halfHeight), halfHeight)
        )
    }

    func deltaPoints(magnification: CGFloat, viewportSize: CGSize? = nil) -> CGSize {
        let safeMagnification = max(magnification, 0.1)
        let primary = clampedPrimaryOffset(viewportSize: viewportSize)
        let secondary = clampedSecondaryOffset(viewportSize: viewportSize)

        return CGSize(
            width: abs(secondary.width - primary.width) / safeMagnification,
            height: abs(secondary.height - primary.height) / safeMagnification
        )
    }

    func formattedReadoutLabels(
        unitType: UnitTypes,
        magnification: CGFloat,
        showCrosshair: Bool,
        showSecondaryCrosshair: Bool,
        showHorizontalRuler: Bool,
        showVerticalRuler: Bool,
        horizontalDistancePoints: CGFloat,
        verticalDistancePoints: CGFloat,
        horizontalMeasurementScale: Double,
        verticalMeasurementScale: Double,
        showMeasurementScaleOverride: Bool,
        viewportSize: CGSize? = nil
    ) -> [String] {
        var labels: [String] = []

        if showCrosshair && showSecondaryCrosshair {
            let delta = deltaPoints(magnification: magnification, viewportSize: viewportSize)
            labels.append(ReadoutDisplayHelper.makePointDeltaReadout(delta: delta))
        }

        if showHorizontalRuler {
            let horizontalComponents = ReadoutDisplayHelper.makeComponents(
                distancePoints: horizontalDistancePoints,
                unitType: unitType,
                measurementScale: horizontalMeasurementScale,
                magnification: magnification,
                showMeasurementScaleOverride: showMeasurementScaleOverride
            )
            labels.append("H:\(horizontalComponents.text)")
        }

        if showVerticalRuler {
            let verticalComponents = ReadoutDisplayHelper.makeComponents(
                distancePoints: verticalDistancePoints,
                unitType: unitType,
                measurementScale: verticalMeasurementScale,
                magnification: magnification,
                showMeasurementScaleOverride: showMeasurementScaleOverride
            )
            labels.append("V:\(verticalComponents.text)")
        }

        return labels
    }

    private func clampedPrimaryOffset(viewportSize: CGSize?) -> CGSize {
        guard let viewportSize else { return primaryCrosshairOffset }
        return clampedOffset(primaryCrosshairOffset, viewportSize: viewportSize)
    }

    private func clampedSecondaryOffset(viewportSize: CGSize?) -> CGSize {
        guard let viewportSize else { return secondaryCrosshairOffset }
        return clampedOffset(secondaryCrosshairOffset, viewportSize: viewportSize)
    }
}
