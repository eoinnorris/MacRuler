//
//  RulerSettingsViewModel.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

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
final class RulerSettingsViewModel {

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

    var horizontalBackgroundThickness: CGFloat {
        Constants.rulerBackgroundLargeThickness * horizontalRulerBackgroundSize.scaleFactor
    }

    var verticalBackgroundThickness: CGFloat {
        Constants.rulerBackgroundLargeThickness * verticalRulerBackgroundSize.scaleFactor
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
        }
//    
//    init(defaults: DefaultsStoring = UserDefaults.standard) {
//        self.defaults = defaults
//        if let storedValue = defaults.string(forKey: PersistenceKeys.unitType),
//           let storedUnit = UnitTypes(rawValue: storedValue) {
//            self.unitType = storedUnit
//        } else {
//            self.unitType = .pixels
//        }
//        
//        self.attachBothRulers = defaults.bool(forKey: PersistenceKeys.attachRulers)
//        if defaults.object(forKey: PersistenceKeys.snapTolerancePoints) != nil {
//            self.snapTolerancePoints = CGFloat(defaults.double(forKey: PersistenceKeys.snapTolerancePoints))
//        }
//        if defaults.object(forKey: PersistenceKeys.snapGridStepPoints) != nil {
//            self.snapGridStepPoints = CGFloat(defaults.double(forKey: PersistenceKeys.snapGridStepPoints))
//        }
//        self.snapToMajorTicks = defaults.object(forKey: PersistenceKeys.snapToMajorTicks) as? Bool ?? false
//    }
}
