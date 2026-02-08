//
//  UnitType+Configuration.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

struct TickConfiguration {
    let pointsPerUnit: CGFloat
    let minorEveryInUnits: CGFloat
    let majorEveryInUnits: CGFloat
    let labelEveryInUnits: CGFloat
    let labelFormatter: (CGFloat) -> String

    var minorEveryInPoints: CGFloat {
        pointsPerUnit * minorEveryInUnits
    }

    var majorStep: Int {
        max(Int((majorEveryInUnits / minorEveryInUnits).rounded()), 1)
    }

    var majorEveryInPoints: CGFloat {
        pointsPerUnit * majorEveryInUnits
    }

    var labelStep: Int {
        max(Int((labelEveryInUnits / minorEveryInUnits).rounded()), 1)
    }
}

extension UnitTypes {
    var tickConfiguration: TickConfiguration {
        switch self {
        case .pixels:
            return TickConfiguration(
                pointsPerUnit: 1,
                minorEveryInUnits: 10,
                majorEveryInUnits: 50,
                labelEveryInUnits: 200,
                labelFormatter: { value in "\(Int(value.rounded()))" }
            )
        case .mm:
            return TickConfiguration(
                pointsPerUnit: 72 / 25.4,
                minorEveryInUnits: 1,
                majorEveryInUnits: 5,
                labelEveryInUnits: 10,
                labelFormatter: { value in "\(Int(value.rounded()))" }
            )
        case .cm:
            return TickConfiguration(
                pointsPerUnit: 72 / 2.54,
                minorEveryInUnits: 0.1,
                majorEveryInUnits: 0.5,
                labelEveryInUnits: 1,
                labelFormatter: { value in "\(Int(value.rounded()))" }
            )
        case .inches:
            return TickConfiguration(
                pointsPerUnit: 72,
                minorEveryInUnits: 0.125,
                majorEveryInUnits: 0.25,
                labelEveryInUnits: 1,
                labelFormatter: { value in "\(Int(value.rounded()))" }
            )
        }
    }

    var unitSymbol: String {
        switch self {
        case .pixels:
            return "pt"
        case .mm:
            return "mm"
        case .cm:
            return "cm"
        case .inches:
            return "in"
        }
    }

    func formattedDistance(points: CGFloat, screenScale: Double) -> String {
        let unitValue = points / tickConfiguration.pointsPerUnit
        let formatted: String
        switch self {
        case .pixels:
            formatted = String(Int(unitValue.rounded()))
        case .mm:
            formatted = String(format: "%.1f", unitValue / screenScale)
        case .cm, .inches:
            formatted = String(format: "%.2f", unitValue /  screenScale)
        }
        return formatted
    }
}
