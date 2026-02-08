//
//  UnitTypes.swift
//  MacRuler
//
//  Created by Eoin Kortext on 08/02/2026.
//

import SwiftUI

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
