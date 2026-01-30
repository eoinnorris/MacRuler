//
//  DividerKeyInput.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import Foundation

enum DividerKeyDirection: String {
    case left
    case right
}



final class  DividerKeyNotification:Sendable {
    static let name = Notification.Name("DividerKeyNotification")
    static let directionKey = "direction"
    static let isDoubleKey = "isDouble"
    
    static func post(direction: DividerKeyDirection, isDouble: Bool) {
        NotificationCenter.default.post(
            name: DividerKeyNotification.name,
            object: nil,
            userInfo: [
                DividerKeyNotification.directionKey: direction.rawValue,
                DividerKeyNotification.isDoubleKey: isDouble
            ]
        )
    }
}
