//
//  Constants.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import Foundation

import AppKit

struct Contants {
    static var screenScale: Double {
        if let scale = NSScreen.main?.backingScaleFactor {
            return min(scale, 2.0)
        }
        return 2.0
    }
}
