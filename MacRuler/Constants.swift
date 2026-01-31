//
//  Constants.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import Foundation

import AppKit

struct Constants {
    static var screenScale: Double {
        if let scale = NSScreen.main?.backingScaleFactor {
            return min(scale, 2.0)
        }
        return 2.0
    }
    
    static let horizontalHeight = 144.0
    static let minHRulerWidth = 100.0
    static let verticalWidth = 144.0

    static func approximateLabelSize(
        text: String,
        fontSize: CGFloat,
        screenScale: CGFloat,
        averageCharacterWidthFactor: CGFloat = 0.6
    ) -> CGSize {
        // Average width of a character ≈ 0.55–0.65 × font size
        let width = CGFloat(text.count) * fontSize * averageCharacterWidthFactor
        let height = fontSize * 1.2   // line height approximation

        // Canvas works in points; scale only if you explicitly want pixel accuracy
        return CGSize(
            width: width,
            height: height
        )
    }
    
    static func globalRectToSCRect(_ r: CGRect, containerHeight H: CGFloat) -> CGRect {
        CGRect(
            x: r.origin.x,
            y: H - r.origin.y - r.size.height,
            width: r.size.width,
            height: r.size.height
        )
    }

    static func scRectToGlobalRect(_ r: CGRect, containerHeight H: CGFloat) -> CGRect {
        CGRect(
            x: r.origin.x,
            y: H - r.origin.y - r.size.height,
            width: r.size.width,
            height: r.size.height
        )
    }


}
