//
//  RulerSettingsViewModel.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI


@Observable
final class RulerSettingsViewModel {
    var unitType: UnitTyoes = .pixels
}

enum UnitTyoes {
    case mm
    case inches
    case pixels
}
