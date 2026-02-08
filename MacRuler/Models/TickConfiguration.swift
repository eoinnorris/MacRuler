//
//  TickConfiguration.swift
//  MacRuler
//
//  Created by Eoin Kortext on 08/02/2026.
//

import Swift
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
