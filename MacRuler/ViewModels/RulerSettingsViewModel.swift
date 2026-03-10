//
//  RulerSettingsViewModel.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

enum MeasurementScaleMode: String, CaseIterable, Identifiable {
    case autoDisplay
    case sourceCapture
    case manual

    var id: Self { self }

    var displayName: String {
        switch self {
        case .autoDisplay:
            "Auto (Display)"
        case .sourceCapture:
            "Source Capture"
        case .manual:
            "Manual"
        }
    }
}



enum MagnifierCrosshairPreset: String, CaseIterable, Identifiable {
    case classic
    case highContrast
    case minimal

    var id: Self { self }

    var displayName: String {
        switch self {
        case .classic:
            "Classic"
        case .highContrast:
            "High Contrast"
        case .minimal:
            "Minimal"
        }
    }
}

enum MagnifierCrosshairColor: String, CaseIterable, Identifiable {
    case white
    case yellow
    case cyan
    case green
    case red

    var id: Self { self }

    var displayName: String {
        switch self {
        case .white:
            "White"
        case .yellow:
            "Yellow"
        case .cyan:
            "Cyan"
        case .green:
            "Green"
        case .red:
            "Red"
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .white:
            .white
        case .yellow:
            .yellow
        case .cyan:
            .cyan
        case .green:
            .green
        case .red:
            .red
        }
    }
}

enum RulerBackgroundSize: String, CaseIterable {
    case large
    case small

    var scaleFactor: CGFloat {
        switch self {
        case .large:
            1.0
        case .small:
            0.5
        }
    }
}

@Observable
@MainActor
@preconcurrency final class RulerSettingsViewModel {

    /// Process-wide shared settings used by the live app runtime.
    /// Access on the main actor when mutating from UI code.
    static let shared = RulerSettingsViewModel()

    private let defaults: DefaultsStoring
    
    var unitType: UnitTypes {
        didSet {
            defaults.set(unitType.rawValue, forKey: PersistenceKeys.unitType)
        }
    }

    var attachBothRulers: Bool {
        didSet {
            defaults.set(attachBothRulers, forKey: PersistenceKeys.attachRulers)
        }
    }

    var snapTolerancePoints: CGFloat {
        didSet {
            defaults.set(Double(snapTolerancePoints), forKey: PersistenceKeys.snapTolerancePoints)
        }
    }

    var snapGridStepPoints: CGFloat? {
        didSet {
            if let snapGridStepPoints {
                defaults.set(Double(snapGridStepPoints), forKey: PersistenceKeys.snapGridStepPoints)
            } else {
                defaults.removeObject(forKey: PersistenceKeys.snapGridStepPoints)
            }
        }
    }

    var snapToMajorTicks: Bool {
        didSet {
            defaults.set(snapToMajorTicks, forKey: PersistenceKeys.snapToMajorTicks)
        }
    }

    var horizontalRulerLocked: Bool

    var verticalRulerLocked: Bool

    var horizontalRulerBackgroundSize: RulerBackgroundSize {
        didSet {
            defaults.set(horizontalRulerBackgroundSize.rawValue, forKey: PersistenceKeys.horizontalRulerBackgroundSize)
        }
    }

    var verticalRulerBackgroundSize: RulerBackgroundSize {
        didSet {
            defaults.set(verticalRulerBackgroundSize.rawValue, forKey: PersistenceKeys.verticalRulerBackgroundSize)
        }
    }

    var measurementScaleMode: MeasurementScaleMode {
        didSet {
            defaults.set(measurementScaleMode.rawValue, forKey: PersistenceKeys.measurementScaleMode)
        }
    }

    var manualMeasurementScale: Double {
        didSet {
            let clampedScale = Self.clampMeasurementScale(manualMeasurementScale)
            if clampedScale != manualMeasurementScale {
                manualMeasurementScale = clampedScale
                return
            }
            defaults.set(manualMeasurementScale, forKey: PersistenceKeys.measurementScaleManualValue)
        }
    }

    var showMeasurementScaleOverrideBadge: Bool {
        didSet {
            defaults.set(showMeasurementScaleOverrideBadge, forKey: PersistenceKeys.measurementScaleBadgeEnabled)
        }
    }

    var showMagnifierPixelGrid: Bool {
        didSet {
            defaults.set(showMagnifierPixelGrid, forKey: PersistenceKeys.magnifierPixelGridEnabled)
        }
    }

    var showMagnifierCrosshair: Bool {
        didSet {
            defaults.set(showMagnifierCrosshair, forKey: PersistenceKeys.magnifierCrosshairEnabled)
        }
    }

    var showMagnifierSecondaryCrosshair: Bool {
        didSet {
            defaults.set(showMagnifierSecondaryCrosshair, forKey: PersistenceKeys.magnifierSecondaryCrosshairEnabled)
        }
    }



    var magnifierCrosshairLineWidth: Double {
        didSet {
            let clampedLineWidth = min(max(magnifierCrosshairLineWidth, 0.5), 5)
            if clampedLineWidth != magnifierCrosshairLineWidth {
                magnifierCrosshairLineWidth = clampedLineWidth
                return
            }
            defaults.set(magnifierCrosshairLineWidth, forKey: PersistenceKeys.magnifierCrosshairLineWidth)
        }
    }

    var magnifierCrosshairColor: MagnifierCrosshairColor {
        didSet {
            defaults.set(magnifierCrosshairColor.rawValue, forKey: PersistenceKeys.magnifierCrosshairColor)
        }
    }

    var magnifierCrosshairDualStrokeEnabled: Bool {
        didSet {
            defaults.set(
                magnifierCrosshairDualStrokeEnabled,
                forKey: PersistenceKeys.magnifierCrosshairDualStrokeEnabled
            )
        }
    }

    var magnifierCrosshairPreset: MagnifierCrosshairPreset {
        didSet {
            defaults.set(magnifierCrosshairPreset.rawValue, forKey: PersistenceKeys.magnifierCrosshairPreset)
        }
    }

    var showMagnifierReadoutCenterPixel: Bool {
        didSet {
            defaults.set(showMagnifierReadoutCenterPixel, forKey: PersistenceKeys.magnifierReadoutCenterPixelEnabled)
        }
    }

    var showMagnifierReadoutConvertedCoordinates: Bool {
        didSet {
            defaults.set(
                showMagnifierReadoutConvertedCoordinates,
                forKey: PersistenceKeys.magnifierReadoutConvertedCoordinatesEnabled
            )
        }
    }

    var showMagnifierReadoutColor: Bool {
        didSet {
            defaults.set(showMagnifierReadoutColor, forKey: PersistenceKeys.magnifierReadoutColorEnabled)
        }
    }

    var showMagnifierReadoutSecondaryReadouts: Bool {
        didSet {
            defaults.set(
                showMagnifierReadoutSecondaryReadouts,
                forKey: PersistenceKeys.magnifierReadoutSecondaryReadoutsEnabled
            )
        }
    }

    var horizontalBackgroundThickness: CGFloat {
        Constants.rulerBackgroundLargeThickness * horizontalRulerBackgroundSize.scaleFactor
    }

    var verticalBackgroundThickness: CGFloat {
        Constants.rulerBackgroundLargeThickness * verticalRulerBackgroundSize.scaleFactor
    }

    func effectiveMeasurementScale(displayScale: Double) -> Double {
        effectiveMeasurementScale(
            displayScale: displayScale,
            sourceCaptureScale: displayScale
        )
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

    var shouldShowMeasurementScaleOverride: Bool {
        showMeasurementScaleOverrideBadge && measurementScaleMode == .manual
    }

    func applyMagnifierCrosshairPreset(_ preset: MagnifierCrosshairPreset) {
        magnifierCrosshairPreset = preset

        switch preset {
        case .classic:
            magnifierCrosshairLineWidth = 1
            magnifierCrosshairColor = .white
            magnifierCrosshairDualStrokeEnabled = true
        case .highContrast:
            magnifierCrosshairLineWidth = 2
            magnifierCrosshairColor = .yellow
            magnifierCrosshairDualStrokeEnabled = true
        case .minimal:
            magnifierCrosshairLineWidth = 0.5
            magnifierCrosshairColor = .cyan
            magnifierCrosshairDualStrokeEnabled = false
        }
    }

    private static func clampMeasurementScale(_ value: Double) -> Double {
        min(max(value, 0.5), 4.0)
    }
    
    init(defaults: DefaultsStoring = UserDefaults.standard) {
            self.defaults = defaults

            // unitType with default
            if let storedValue = defaults.string(forKey: PersistenceKeys.unitType),
               let storedUnit = UnitTypes(rawValue: storedValue) {
                self.unitType = storedUnit
            } else {
                self.unitType = .pixels
            }

            // attachBothRulers with default
            self.attachBothRulers = defaults.object(forKey: PersistenceKeys.attachRulers) as? Bool ?? false

            // snapTolerancePoints with default (choose a sensible fallback, e.g., 4 points)
            if defaults.object(forKey: PersistenceKeys.snapTolerancePoints) != nil {
                self.snapTolerancePoints = CGFloat(defaults.double(forKey: PersistenceKeys.snapTolerancePoints))
            } else {
                self.snapTolerancePoints = 4
            }

            // snapGridStepPoints with default to nil when not stored
            if defaults.object(forKey: PersistenceKeys.snapGridStepPoints) != nil {
                self.snapGridStepPoints = CGFloat(defaults.double(forKey: PersistenceKeys.snapGridStepPoints))
            } else {
                self.snapGridStepPoints = nil
            }

            // snapToMajorTicks with default
            self.snapToMajorTicks = defaults.object(forKey: PersistenceKeys.snapToMajorTicks) as? Bool ?? false

            self.horizontalRulerLocked = false
            self.verticalRulerLocked = false

            if let raw = defaults.string(forKey: PersistenceKeys.horizontalRulerBackgroundSize),
               let backgroundSize = RulerBackgroundSize(rawValue: raw) {
                self.horizontalRulerBackgroundSize = backgroundSize
            } else {
                self.horizontalRulerBackgroundSize = .large
            }

            if let raw = defaults.string(forKey: PersistenceKeys.verticalRulerBackgroundSize),
               let backgroundSize = RulerBackgroundSize(rawValue: raw) {
                self.verticalRulerBackgroundSize = backgroundSize
            } else {
                self.verticalRulerBackgroundSize = .large
            }

            if let storedMode = defaults.string(forKey: PersistenceKeys.measurementScaleMode),
               let mode = MeasurementScaleMode(rawValue: storedMode) {
                self.measurementScaleMode = mode
            } else {
                self.measurementScaleMode = .autoDisplay
            }

            if defaults.object(forKey: PersistenceKeys.measurementScaleManualValue) != nil {
                self.manualMeasurementScale = Self.clampMeasurementScale(
                    defaults.double(forKey: PersistenceKeys.measurementScaleManualValue)
                )
            } else {
                self.manualMeasurementScale = 2.0
            }

            self.showMeasurementScaleOverrideBadge =
                defaults.object(forKey: PersistenceKeys.measurementScaleBadgeEnabled) as? Bool ?? true

            self.showMagnifierPixelGrid =
                defaults.object(forKey: PersistenceKeys.magnifierPixelGridEnabled) as? Bool ?? true

            self.showMagnifierCrosshair =
                defaults.object(forKey: PersistenceKeys.magnifierCrosshairEnabled) as? Bool ?? true

            self.showMagnifierSecondaryCrosshair =
                defaults.object(forKey: PersistenceKeys.magnifierSecondaryCrosshairEnabled) as? Bool ?? false



            if defaults.object(forKey: PersistenceKeys.magnifierCrosshairLineWidth) != nil {
                self.magnifierCrosshairLineWidth = min(
                    max(defaults.double(forKey: PersistenceKeys.magnifierCrosshairLineWidth), 0.5),
                    5
                )
            } else {
                self.magnifierCrosshairLineWidth = 1
            }

            if let raw = defaults.string(forKey: PersistenceKeys.magnifierCrosshairColor),
               let crosshairColor = MagnifierCrosshairColor(rawValue: raw) {
                self.magnifierCrosshairColor = crosshairColor
            } else {
                self.magnifierCrosshairColor = .white
            }

            self.magnifierCrosshairDualStrokeEnabled =
                defaults.object(forKey: PersistenceKeys.magnifierCrosshairDualStrokeEnabled) as? Bool ?? true

            if let raw = defaults.string(forKey: PersistenceKeys.magnifierCrosshairPreset),
               let preset = MagnifierCrosshairPreset(rawValue: raw) {
                self.magnifierCrosshairPreset = preset
            } else {
                self.magnifierCrosshairPreset = .classic
            }

            self.showMagnifierReadoutCenterPixel =
                defaults.object(forKey: PersistenceKeys.magnifierReadoutCenterPixelEnabled) as? Bool ?? false

            self.showMagnifierReadoutConvertedCoordinates =
                defaults.object(forKey: PersistenceKeys.magnifierReadoutConvertedCoordinatesEnabled) as? Bool ?? false

            self.showMagnifierReadoutColor =
                defaults.object(forKey: PersistenceKeys.magnifierReadoutColorEnabled) as? Bool ?? false

            self.showMagnifierReadoutSecondaryReadouts =
                defaults.object(forKey: PersistenceKeys.magnifierReadoutSecondaryReadoutsEnabled) as? Bool ?? false
        }
}
