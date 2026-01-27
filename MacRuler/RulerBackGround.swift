//
//  RulerBackGround.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

struct RulerBackGround : View {
    
    let rulerType:RulerType
    
    var body: some View {
         switch rulerType {
            case .vertical:
             EmptyView()
         case .horizontal:
             HorizontalRulerBackGround
        }
    }
    
    var HorizontalRulerBackGround: some View {
        
        ZStack {
            
            horizontalGradient
            // ✅ Tick marks
            Canvas { context, size in
                let h = size.height
                let minorEvery: CGFloat = 10   // points (roughly “ticks”)
                let majorEvery: CGFloat = 50

                var minor = Path()
                var major = Path()

                var x: CGFloat = 0
                while x <= size.width {
                    if x.truncatingRemainder(dividingBy: majorEvery) == 0 {
                        major.move(to: CGPoint(x: x, y: h))
                        major.addLine(to: CGPoint(x: x, y: h * 0.35))
                    } else {
                        minor.move(to: CGPoint(x: x, y: h))
                        minor.addLine(to: CGPoint(x: x, y: h * 0.6))
                    }
                    x += minorEvery
                }

                context.stroke(minor, with: .color(.black.opacity(0.35)), lineWidth: 1)
                context.stroke(major, with: .color(.black.opacity(0.65)), lineWidth: 1.2)

                // Optional baseline
                var base = Path()
                base.move(to: CGPoint(x: 0, y: h - 1))
                base.addLine(to: CGPoint(x: size.width, y: h - 1))
                context.stroke(base, with: .color(.black.opacity(0.35)), lineWidth: 1)
            }
            .padding(.horizontal, -1)
            .padding(.vertical,-1)
        }
    }
    
    var horizontalGradient: some View {
        
        ZStack {
            // ✅ Yellow gradient background
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.85),
                    Color.init(hex: "#FFBE00"),
                    Color.yellow.opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
