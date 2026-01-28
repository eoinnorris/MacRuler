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

    var unitType: UnitTyoes {
        didSet {
            defaults.set(unitType.rawValue, forKey: PersistenceKeys.unitType)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let storedValue = defaults.string(forKey: PersistenceKeys.unitType),
           let storedUnit = UnitTyoes(rawValue: storedValue) {
            self.unitType = storedUnit
        } else {
            self.unitType = .pixels
        }
    }
}

enum UnitTyoes: String, CaseIterable, Identifiable {
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
