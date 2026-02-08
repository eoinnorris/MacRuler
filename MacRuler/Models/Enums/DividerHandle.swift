//
//  DividerHandle.swift
//  MacRuler
//
//  Created by Eoin Kortext on 08/02/2026.
//


enum DividerHandle: String, CaseIterable, Identifiable {
    case left
    case right

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .left:
            return "Select left handle"
        case .right:
            return "Select right handle"
        }
    }
}
