//
//  DebugSettingsModel.swift
//  MacRuler
//
//  Created by OpenAI on 2026-01-26.
//

import SwiftUI

@Observable
final class DebugSettingsModel {
    /// Process-wide shared debug settings used by the live app runtime.
    /// Access on the main actor when mutating from UI code.
    static let shared = DebugSettingsModel()

    var showWindowBackground = false

    init() {}
}
