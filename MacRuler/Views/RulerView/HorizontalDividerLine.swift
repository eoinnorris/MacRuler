//
//  HorizontalDividerLine.swift
//  MacRuler
//
//  Created by OpenAI Codex on 2026-03-09.
//

import SwiftUI

struct HorizontalDividerLine: View {
    let y: CGFloat
    let width: CGFloat
    let backingScale: CGFloat
    let isHovering: Bool

    private var lineWidth: CGFloat {
        if isHovering {
            return max(5, 7 / backingScale)
        } else {
            return max(1, 2 / backingScale)
        }
    }

    var body: some View {
        Rectangle()
            .fill(isHovering ?
                  AnyShapeStyle(
                    LinearGradient(
                        colors: [ Color.black.opacity(0.4),
                                  Color.gray.opacity(0.9),
                                  Color.white.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                  ) :
                  AnyShapeStyle(Color.gray.opacity(0.75))
            )
            .frame(width: width, height: lineWidth)
            .position(x: width / 2, y: y)
    }
}
