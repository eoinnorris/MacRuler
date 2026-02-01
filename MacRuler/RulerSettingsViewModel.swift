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
    
    var attachBothRulers = false

    var unitType: UnitTyoes {
        didSet {
            defaults.set(unitType.rawValue, forKey: PersistenceKeys.unitType)
        }
    }

    var attachRulers: RulerAttachmentType {
        didSet {
            defaults.set(attachRulers.rawValue, forKey: PersistenceKeys.attachRulers)
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
        
        var attachRulers: RulerAttachmentType = .none
    
        if let storedValue = defaults.string(forKey: PersistenceKeys.attachRulers),
           let storedUnit = RulerAttachmentType(rawValue: storedValue) {
            attachRulers = storedUnit
        } else {
            attachRulers = .none
        }
        self.attachRulers = attachRulers
    }
}

extension RulerSettingsViewModel {

    var verticalToHorizontalBinding: Binding<Bool> {
        Binding(
            get: {
                self.attachRulers == .verticalToHorizontal
            },
            set: { isOn in
                if isOn {
                    self.attachRulers = .verticalToHorizontal
                } else if self.attachRulers == .verticalToHorizontal {
                    self.attachRulers = .none
                }
            }
        )
    }

    var horizontalToVerticalBinding: Binding<Bool> {
        Binding(
            get: {
                self.attachRulers == .horizontalToVertical
            },
            set: { isOn in
                if isOn {
                    self.attachRulers = .horizontalToVertical
                } else if self.attachRulers == .horizontalToVertical {
                    self.attachRulers = .none
                }
            }
        )
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
