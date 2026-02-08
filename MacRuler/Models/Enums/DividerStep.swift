//
//  DividerStep.swift
//  MacRuler
//
//  Created by Eoin Kortext on 08/02/2026.
//

import Swift

enum DividerStep: Int, CaseIterable, Identifiable {
    case one = 1
    case five = 5
    case ten = 10

    var id: Int { rawValue }
    var displayName: String {
        "\(rawValue)px"
    }
}
