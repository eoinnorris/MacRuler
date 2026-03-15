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

    enum MagnifierColorOutputFormat: String, CaseIterable, Identifiable {
        case hex
        case rgb
        case hsl
        case swiftUIColor
        case nsColor

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .hex: "HEX"
            case .rgb: "RGB"
            case .hsl: "HSL"
            case .swiftUIColor: "SwiftUI Color"
            case .nsColor: "NSColor"
            }
        }
    }

    static let defaultSecondaryOffset = CGSize(width: 24, height: 24)

    var primaryOffset: CGSize
    var secondaryOffset: CGSize
    var isPrimaryLocked = false
    var isSecondaryLocked = false
    var selectedCrosshair: CrosshairSelection = .primary
    private let defaults: DefaultsStoring

    var selectedColorOutputFormat: MagnifierColorOutputFormat {
        didSet {
            defaults.magnifierColorOutputFormat = selectedColorOutputFormat
        }
    }

    var lastPickedColorSample: CenterSampleReadout?

    var showMagnifierCrosshair: Bool {
        didSet {
            defaults.magnifierCrosshairEnabled = showMagnifierCrosshair
        }
    }

    init(primaryOffset: CGSize = .zero,
         secondaryOffset: CGSize,
         defaults: DefaultsStoring = UserDefaults.standard)
    {
        self.defaults = defaults
        self.primaryOffset = primaryOffset
        self.secondaryOffset = secondaryOffset
        self.showMagnifierCrosshair = defaults.magnifierCrosshairEnabled
        self.showCrosshair = defaults.magnifierCrosshairEnabled
        self.showSecondaryCrosshair = defaults.magnifierSecondaryCrosshairEnabled
        self.showPixelGrid = defaults.magnifierPixelGridEnabled
        self.crosshairLineWidth = defaults.magnifierCrosshairLineWidth
        self.crosshairColor = defaults.magnifierCrosshairColor
        self.crosshairDualStrokeEnabled = defaults.magnifierCrosshairDualStrokeEnabled
        self.unitType = defaults.magnifierUnitType
        self.showCenterPixelCoordinates = defaults.showCenterPixelCoordinates
        self.showConvertedCenterCoordinates = defaults.showConvertedCenterCoordinates
        self.showColorValues = defaults.showMagnifierReadoutColor
        self.showSecondaryReadouts = defaults.showMagnifierSecondaryReadouts
        self.measurementScaleMode = defaults.measurementScaleModeValue
        self.manualMeasurementScale = defaults.manualMeasurementScaleValue
        self.showMeasurementScaleOverrideBadge = defaults.measurementScaleOverrideBadgeEnabled
        self.selectedColorOutputFormat = defaults.magnifierColorOutputFormat
    }


    var showCrosshair: Bool {
        didSet {
            primaryOffset = .zero
            showMagnifierCrosshair = showCrosshair
        }
    }

    var showSecondaryCrosshair: Bool = true {
        didSet {
            defaults.magnifierSecondaryCrosshairEnabled = showSecondaryCrosshair
            if !showSecondaryCrosshair {
                resetSecondaryOffset()
            }
        }
    }

    var showPixelGrid: Bool {
        didSet {
            defaults.magnifierPixelGridEnabled = showPixelGrid
        }
    }

    var crosshairLineWidth: Double {
        didSet {
            let clampedLineWidth = min(max(crosshairLineWidth, 0.5), 5)
            if clampedLineWidth != crosshairLineWidth {
                crosshairLineWidth = clampedLineWidth
                return
            }
            defaults.magnifierCrosshairLineWidth = crosshairLineWidth
        }
    }

    var crosshairColor: MagnifierCrosshairColor {
        didSet {
            defaults.magnifierCrosshairColor = crosshairColor
        }
    }

    var crosshairDualStrokeEnabled: Bool {
        didSet {
            defaults.magnifierCrosshairDualStrokeEnabled = crosshairDualStrokeEnabled
        }
    }

    var unitType: UnitTypes {
        didSet {
            defaults.magnifierUnitType = unitType
        }
    }

    var showCenterPixelCoordinates: Bool {
        didSet {
            defaults.showCenterPixelCoordinates = showCenterPixelCoordinates
        }
    }

    var showConvertedCenterCoordinates: Bool {
        didSet {
            defaults.showConvertedCenterCoordinates = showConvertedCenterCoordinates
        }
    }

    var showColorValues: Bool {
        didSet {
            defaults.showMagnifierReadoutColor = showColorValues
        }
    }

    var showSecondaryReadouts: Bool {
        didSet {
            defaults.showMagnifierSecondaryReadouts = showSecondaryReadouts
        }
    }

    var measurementScaleMode: MeasurementScaleMode {
        didSet {
            defaults.measurementScaleModeValue = measurementScaleMode
        }
    }

    var manualMeasurementScale: Double {
        didSet {
            let clampedScale = min(max(manualMeasurementScale, 0.5), 4.0)
            if clampedScale != manualMeasurementScale {
                manualMeasurementScale = clampedScale
                return
            }
            defaults.manualMeasurementScaleValue = manualMeasurementScale
        }
    }

    var showMeasurementScaleOverrideBadge: Bool {
        didSet {
            defaults.measurementScaleOverrideBadgeEnabled = showMeasurementScaleOverrideBadge
        }
    }

    var shouldShowMeasurementScaleOverride: Bool {
        showMeasurementScaleOverrideBadge && measurementScaleMode == .manual
    }

    func effectiveMeasurementScale(displayScale: Double, sourceCaptureScale: Double) -> Double {
        switch measurementScaleMode {
        case .autoDisplay:
            max(displayScale, 0.1)
        case .sourceCapture:
            max(sourceCaptureScale, 0.1)
        case .manual:
            manualMeasurementScale
        }
    }

    func formattedColor(for sample: CenterSampleReadout) -> String {
        switch selectedColorOutputFormat {
        case .hex:
            sample.hexValue
        case .rgb:
            sample.rgbLabel
        case .hsl:
            sample.hslLabel
        case .swiftUIColor:
            "Color(red: \(sample.normalizedRGB.red.formatted(.number.precision(.fractionLength(3)))), green: \(sample.normalizedRGB.green.formatted(.number.precision(.fractionLength(3)))), blue: \(sample.normalizedRGB.blue.formatted(.number.precision(.fractionLength(3)))))"
        case .nsColor:
            "NSColor(calibratedRed: \(sample.normalizedRGB.red.formatted(.number.precision(.fractionLength(3)))), green: \(sample.normalizedRGB.green.formatted(.number.precision(.fractionLength(3)))), blue: \(sample.normalizedRGB.blue.formatted(.number.precision(.fractionLength(3)))), alpha: 1.000)"
        }
    }

    @discardableResult
    func copyColor(sample: CenterSampleReadout?) -> String? {
        guard let sample else { return nil }
        let output = formattedColor(for: sample)
        ClipboardWriter.writeString(output)
        return output
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

typealias MagnifierColorOutputFormat = MagnifierCrosshairViewModel.MagnifierColorOutputFormat
