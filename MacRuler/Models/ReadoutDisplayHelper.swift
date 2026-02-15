//
//  ReadoutDisplayHelper.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-15.
//

import CoreGraphics

struct ReadoutDisplayComponents {
    let displayValue: String
    let unitSymbol: String
    let magnificationLabel: String

    var text: String {
        "\(displayValue) \(unitSymbol) • \(magnificationLabel)"
    }
}

enum ReadoutDisplayHelper {
    static func makeComponents(
        distancePoints: CGFloat,
        unitType: UnitTypes,
        screenScale: Double,
        magnification: CGFloat
    ) -> ReadoutDisplayComponents {
        ReadoutDisplayComponents(
            displayValue: unitType.formattedDistance(points: distancePoints, screenScale: screenScale),
            unitSymbol: unitType.unitSymbol,
            magnificationLabel: MagnificationViewModel.formatLabel(magnification)
        )
    }
}
