//
//  OverlayViewModel.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

@Observable
final class OverlayViewModel {
   var leftDividerX: CGFloat?
   var rightDividerX: CGFloat?
   var backingScale: CGFloat = 1.0

    var dividerDistancePixels: Int {
        guard let leftDividerX, let rightDividerX else { return 0 }
        return Int((abs(rightDividerX - leftDividerX) * backingScale).rounded())
    }
    
    func updateDividers(with x: CGFloat) {
        if leftDividerX == nil {
            leftDividerX = x
            return
        }

        if rightDividerX == nil {
            if let leftDividerX, x < leftDividerX {
                rightDividerX = leftDividerX
                self.leftDividerX = x
            } else {
                rightDividerX = x
            }
            return
        }

        guard let leftDividerX, let rightDividerX else { return }

        if x <= leftDividerX {
            self.leftDividerX = x
            return
        }

        if x >= rightDividerX {
            self.rightDividerX = x
            return
        }

        let leftDistance = abs(x - leftDividerX)
        let rightDistance = abs(rightDividerX - x)
        if leftDistance <= rightDistance {
            self.leftDividerX = x
        } else {
            self.rightDividerX = x
        }
    }
    
}
