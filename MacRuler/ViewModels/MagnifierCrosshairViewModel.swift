import CoreGraphics
import Observation
import Foundation

@Observable
@MainActor
final class MagnifierCrosshairViewModel {
    enum CrosshairSelection {
        case primary
        case secondary
    }

    static let defaultSecondaryOffset = CGSize(width: 24, height: 24)

    var primaryOffset: CGSize
    var secondaryOffset: CGSize
    var isPrimaryLocked = false
    var isSecondaryLocked = false
    var selectedCrosshair: CrosshairSelection = .primary
    private let defaults: DefaultsStoring

    var showMagnifierCrosshair: Bool = true {
        didSet {
            defaults.set(showMagnifierCrosshair, forKey: PersistenceKeys.magnifierCrosshairEnabled)
        }
    }
    
    init(primaryOffset: CGSize = .zero,
        secondaryOffset: CGSize,
        defaults: DefaultsStoring = UserDefaults.standard)
    {
        self.defaults = defaults
        self.primaryOffset = primaryOffset
        self.secondaryOffset = secondaryOffset
    }

    
    var showCrosshair: Bool = true {
        didSet {
            primaryOffset = .zero
            defaults.set(showMagnifierCrosshair, forKey: PersistenceKeys.magnifierCrosshairEnabled)
        }
    }
    
    var showSecondaryCrosshair: Bool = true {
        didSet {
            defaults.set(showSecondaryCrosshair, forKey: PersistenceKeys.magnifierSecondaryCrosshairEnabled)
            if !showSecondaryCrosshair {
                resetSecondaryOffset()
            }
        }
    }

    func toggleCrosshairVisibility() {
        showCrosshair.toggle()
    }

    func toggleSecondaryCrosshairVisibility() {
        showSecondaryCrosshair.toggle()
    }

    func nudgeSecondaryCrosshair(x: CGFloat, y: CGFloat) {
        secondaryOffset = CGSize(
            width: secondaryOffset.width + x,
            height: secondaryOffset.height + y
        )
    }

    func nudgeSelectedCrosshair(x: CGFloat, y: CGFloat, showSecondaryCrosshair: Bool) {
        let selectedTarget: CrosshairSelection = {
            if selectedCrosshair == .secondary, showSecondaryCrosshair {
                return .secondary
            }
            return .primary
        }()

        switch selectedTarget {
        case .primary:
            guard !isPrimaryLocked else { return }
            primaryOffset = CGSize(
                width: primaryOffset.width + x,
                height: primaryOffset.height + y
            )
        case .secondary:
            guard !isSecondaryLocked else { return }
            secondaryOffset = CGSize(
                width: secondaryOffset.width + x,
                height: secondaryOffset.height + y
            )
        }
    }

    func resetPrimary() {
        primaryOffset = .zero
    }

    func resetSecondary() {
        secondaryOffset = Self.defaultSecondaryOffset
    }

    func resetAll() {
        primaryOffset = .zero
        secondaryOffset = Self.defaultSecondaryOffset
    }

    func resetAllOffsets() {
        resetAll()
    }

    func resetSecondaryOffset() {
        resetSecondary()
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
        sourceDisplayScale: CGFloat,
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
            sourceDisplayScale: sourceDisplayScale,
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
