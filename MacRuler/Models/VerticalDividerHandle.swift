//
//  VerticalDividerHandle.swift
//  MacRuler
//
//  Created by Eoin Kortext on 08/02/2026.
//

import SwiftUI

enum VerticalDividerHandle: String, CaseIterable, Identifiable {
    case top
    case bottom

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .top:
            return "Select top handle"
        case .bottom:
            return "Select bottom handle"
        }
    }
}
