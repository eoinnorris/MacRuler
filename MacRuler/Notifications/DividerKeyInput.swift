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
    case up
    case down
}

final class DividerKeyNotification: Sendable {
    enum UserInfoKey: String {
        case payload
    }

    struct Payload: Sendable {
        let direction: DividerKeyDirection
        let isDouble: Bool
    }

    static let name = Notification.Name("DividerKeyNotification")
    
    static func post(direction: DividerKeyDirection, isDouble: Bool) {
        let payload = Payload(direction: direction, isDouble: isDouble)
        NotificationCenter.default.post(
            name: DividerKeyNotification.name,
            object: nil,
            userInfo: [
                UserInfoKey.payload.rawValue: payload
            ]
        )
    }

    static func payload(from notification: Notification) -> Payload? {
        notification.userInfo?[UserInfoKey.payload.rawValue] as? Payload
    }
}
