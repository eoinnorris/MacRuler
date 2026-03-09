//
//  DividerLine.swift
//  MacRuler
//
//  Created by OpenAI Codex on 2026-03-09.
//

import SwiftUI

struct DividerLine: View {
    let x: CGFloat
    let height: CGFloat
    let backingScale: CGFloat
    let isHovering: Bool

    private var lineWidth: CGFloat {
        if isHovering {
            return max(5, 7 / backingScale)
        } else {
            return max(1, 3 / backingScale)
        }
    }

    var body: some View {
        Rectangle()
            .fill(isHovering ?
                  AnyShapeStyle(
                    LinearGradient(
                        colors: [Color.black.opacity(0.4),
                                 Color.gray.opacity(0.9),
                                 Color.white.opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                  ) :
                  AnyShapeStyle(Color.gray.opacity(0.75))
            )
            .frame(width: lineWidth, height: height)
            .position(x: x, y: height / 2)
    }
}
