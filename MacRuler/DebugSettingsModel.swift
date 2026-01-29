//
//  DebugSettingsModel.swift
//  MacRuler
//
//  Created by OpenAI on 2026-01-26.
//

import SwiftUI

@Observable
final class DebugSettingsModel {
    static let shared = DebugSettingsModel()

    var showWindowBackground = false

    private init() {}
}
