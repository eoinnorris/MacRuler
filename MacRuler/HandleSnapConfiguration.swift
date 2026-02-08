//
//  HandleSnapConfiguration.swift
//  MacRuler
//
//  Created by OpenAI Codex on 08/02/2026.
//

import SwiftUI

struct HandleSnapConfiguration {
    var snapEnabled: Bool
    var snapTolerancePoints: CGFloat
    var snapGridStepPoints: CGFloat?
    var snapToMajorTicks: Bool

    static let `default` = HandleSnapConfiguration(
        snapEnabled: true,
        snapTolerancePoints: 6,
        snapGridStepPoints: nil,
        snapToMajorTicks: true
    )
}

