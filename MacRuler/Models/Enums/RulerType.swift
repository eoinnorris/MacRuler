//
//  RulerType.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//


enum RulerType {
    case vertical
    case horizontal
}

enum RulerAttachmentType: String, CaseIterable, Identifiable {
    case verticalToHorizontal
    case horizontalToVertical
    case none
    var id: Self { self }
}
