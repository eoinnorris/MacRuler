import Foundation

extension DefaultsStoring {
    var magnifierCrosshairEnabled: Bool {
        get { object(forKey: PersistenceKeys.magnifierCrosshairEnabled) as? Bool ?? true }
        set { set(newValue, forKey: PersistenceKeys.magnifierCrosshairEnabled) }
    }

    var magnifierSecondaryCrosshairEnabled: Bool {
        get { object(forKey: PersistenceKeys.magnifierSecondaryCrosshairEnabled) as? Bool ?? false }
        set { set(newValue, forKey: PersistenceKeys.magnifierSecondaryCrosshairEnabled) }
    }

    var magnifierPixelGridEnabled: Bool {
        get { object(forKey: PersistenceKeys.magnifierPixelGridEnabled) as? Bool ?? true }
        set { set(newValue, forKey: PersistenceKeys.magnifierPixelGridEnabled) }
    }

    var magnifierCrosshairLineWidth: Double {
        get {
            guard object(forKey: PersistenceKeys.magnifierCrosshairLineWidth) != nil else {
                return 1
            }
            return min(max(double(forKey: PersistenceKeys.magnifierCrosshairLineWidth), 0.5), 5)
        }
        set { set(min(max(newValue, 0.5), 5), forKey: PersistenceKeys.magnifierCrosshairLineWidth) }
    }

    var magnifierCrosshairColor: MagnifierCrosshairColor {
        get {
            guard let raw = string(forKey: PersistenceKeys.magnifierCrosshairColor),
                  let color = MagnifierCrosshairColor(rawValue: raw)
            else {
                return .white
            }
            return color
        }
        set { set(newValue.rawValue, forKey: PersistenceKeys.magnifierCrosshairColor) }
    }

    var magnifierCrosshairDualStrokeEnabled: Bool {
        get { object(forKey: PersistenceKeys.magnifierCrosshairDualStrokeEnabled) as? Bool ?? true }
        set { set(newValue, forKey: PersistenceKeys.magnifierCrosshairDualStrokeEnabled) }
    }

    var magnifierUnitType: UnitTypes {
        get {
            guard let raw = string(forKey: PersistenceKeys.unitType),
                  let unitType = UnitTypes(rawValue: raw)
            else {
                return .pixels
            }
            return unitType
        }
        set { set(newValue.rawValue, forKey: PersistenceKeys.unitType) }
    }

    var showCenterPixelCoordinates: Bool {
        get { object(forKey: PersistenceKeys.magnifierReadoutCenterPixelEnabled) as? Bool ?? true }
        set { set(newValue, forKey: PersistenceKeys.magnifierReadoutCenterPixelEnabled) }
    }

    var showConvertedCenterCoordinates: Bool {
        get { object(forKey: PersistenceKeys.magnifierReadoutConvertedCoordinatesEnabled) as? Bool ?? false }
        set { set(newValue, forKey: PersistenceKeys.magnifierReadoutConvertedCoordinatesEnabled) }
    }

    var showMagnifierReadoutColor: Bool {
        get { object(forKey: PersistenceKeys.magnifierReadoutColorEnabled) as? Bool ?? false }
        set { set(newValue, forKey: PersistenceKeys.magnifierReadoutColorEnabled) }
    }

    var showMagnifierSecondaryReadouts: Bool {
        get { object(forKey: PersistenceKeys.magnifierReadoutSecondaryReadoutsEnabled) as? Bool ?? false }
        set { set(newValue, forKey: PersistenceKeys.magnifierReadoutSecondaryReadoutsEnabled) }
    }

    var measurementScaleModeValue: MeasurementScaleMode {
        get {
            guard let raw = string(forKey: PersistenceKeys.measurementScaleMode),
                  let mode = MeasurementScaleMode(rawValue: raw)
            else {
                return .autoDisplay
            }
            return mode
        }
        set { set(newValue.rawValue, forKey: PersistenceKeys.measurementScaleMode) }
    }

    var manualMeasurementScaleValue: Double {
        get {
            guard object(forKey: PersistenceKeys.measurementScaleManualValue) != nil else {
                return 2.0
            }
            return min(max(double(forKey: PersistenceKeys.measurementScaleManualValue), 0.5), 4.0)
        }
        set { set(min(max(newValue, 0.5), 4.0), forKey: PersistenceKeys.measurementScaleManualValue) }
    }

    var measurementScaleOverrideBadgeEnabled: Bool {
        get { object(forKey: PersistenceKeys.measurementScaleBadgeEnabled) as? Bool ?? true }
        set { set(newValue, forKey: PersistenceKeys.measurementScaleBadgeEnabled) }
    }

    var magnifierColorOutputFormat: MagnifierColorOutputFormat {
        get {
            guard let raw = string(forKey: PersistenceKeys.magnifierColorOutputFormat),
                  let format = MagnifierColorOutputFormat(rawValue: raw)
            else {
                return .hex
            }
            return format
        }
        set { set(newValue.rawValue, forKey: PersistenceKeys.magnifierColorOutputFormat) }
    }

}
