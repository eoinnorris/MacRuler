//
//  RulerSettingsViewModel.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

@Observable
final class RulerSettingsViewModel {

    static var shared = RulerSettingsViewModel()

    private let defaults: UserDefaults
    
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

    var snapEnabled: Bool {
        didSet {
            defaults.set(snapEnabled, forKey: PersistenceKeys.snapEnabled)
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

    var handleSnapConfiguration: HandleSnapConfiguration {
        HandleSnapConfiguration(
            snapEnabled: snapEnabled,
            snapTolerancePoints: snapTolerancePoints,
            snapGridStepPoints: snapGridStepPoints,
            snapToMajorTicks: snapToMajorTicks
        )
    }
    

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let storedValue = defaults.string(forKey: PersistenceKeys.unitType),
           let storedUnit = UnitTypes(rawValue: storedValue) {
            self.unitType = storedUnit
        } else {
            self.unitType = .pixels
        }
        
        self.attachBothRulers = defaults.bool(forKey: PersistenceKeys.attachRulers)
        self.snapEnabled = defaults.object(forKey: PersistenceKeys.snapEnabled) as? Bool ?? HandleSnapConfiguration.default.snapEnabled
        if defaults.object(forKey: PersistenceKeys.snapTolerancePoints) != nil {
            self.snapTolerancePoints = CGFloat(defaults.double(forKey: PersistenceKeys.snapTolerancePoints))
        } else {
            self.snapTolerancePoints = HandleSnapConfiguration.default.snapTolerancePoints
        }
        if defaults.object(forKey: PersistenceKeys.snapGridStepPoints) != nil {
            self.snapGridStepPoints = CGFloat(defaults.double(forKey: PersistenceKeys.snapGridStepPoints))
        } else {
            self.snapGridStepPoints = HandleSnapConfiguration.default.snapGridStepPoints
        }
        self.snapToMajorTicks = defaults.object(forKey: PersistenceKeys.snapToMajorTicks) as? Bool ?? HandleSnapConfiguration.default.snapToMajorTicks
    }
}

enum UnitTypes: String, CaseIterable, Identifiable {
    case cm
    case mm
    case inches
    case pixels

    var id: Self { self }

    var displayName: String {
        switch self {
        case .cm:
            return "Centimeters"
        case .mm:
            return "Millimeters"
        case .inches:
            return "Inches"
        case .pixels:
            return "Points"
        }
    }
}
