//
//  RulerBackGround.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

struct RulerBackGround : View {
    
    let rulerType:RulerType
    @Environment(RulerSettingsViewModel.self) private var rulerSettingsViewModel
    
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
                let tickConfig = tickConfiguration(for: rulerSettingsViewModel.unitType)
                let minorEvery = tickConfig.minorEveryInPoints
                let majorStep = tickConfig.majorStep
                let labelStep = tickConfig.labelStep
                let labelFont = Font.system(size: 9, weight: .medium)

                var minor = Path()
                var major = Path()

                let totalTicks = Int(size.width / minorEvery)
                for tickIndex in 0...totalTicks {
                    let x = CGFloat(tickIndex) * minorEvery
                    if tickIndex.isMultiple(of: majorStep) {
                        major.move(to: CGPoint(x: x, y: h))
                        major.addLine(to: CGPoint(x: x, y: h * 0.35))
                    } else {
                        minor.move(to: CGPoint(x: x, y: h))
                        minor.addLine(to: CGPoint(x: x, y: h * 0.6))
                    }
                }

                context.stroke(minor, with: .color(.black.opacity(0.35)), lineWidth: 1)
                context.stroke(major, with: .color(.black.opacity(0.65)), lineWidth: 1.2)

                if labelStep > 0 {
                    for tickIndex in 0...totalTicks where tickIndex.isMultiple(of: labelStep) && tickIndex > 0 {
                        let x = CGFloat(tickIndex) * minorEvery
                        let unitValue = CGFloat(tickIndex) * tickConfig.minorEveryInUnits
                        let label = tickConfig.labelFormatter(unitValue)
                        context.draw(
                            Text(label)
                                .font(labelFont)
                                .foregroundStyle(Color.black.opacity(0.7)),
                            at: CGPoint(x: x + 2, y: h * 0.1),
                            anchor: .topLeading
                        )
                    }
                }

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

    private func tickConfiguration(for unitType: UnitTyoes) -> TickConfiguration {
        switch unitType {
        case .pixels:
            return TickConfiguration(
                pointsPerUnit: 1,
                minorEveryInUnits: 10,
                majorEveryInUnits: 50,
                labelEveryInUnits: 250,
                labelFormatter: { value in "\(Int(value.rounded()))" }
            )
        case .mm:
            return TickConfiguration(
                pointsPerUnit: 72 / 25.4,
                minorEveryInUnits: 1,
                majorEveryInUnits: 5,
                labelEveryInUnits: 10,
                labelFormatter: { value in "\(Int(value.rounded()))" }
            )
        case .cm:
            return TickConfiguration(
                pointsPerUnit: 72 / 2.54,
                minorEveryInUnits: 0.1,
                majorEveryInUnits: 0.5,
                labelEveryInUnits: 1,
                labelFormatter: { value in "\(Int(value.rounded()))" }
            )
        case .inches:
            return TickConfiguration(
                pointsPerUnit: 72,
                minorEveryInUnits: 0.125,
                majorEveryInUnits: 0.25,
                labelEveryInUnits: 1,
                labelFormatter: { value in "\(Int(value.rounded()))" }
            )
        }
    }
}

private struct TickConfiguration {
    let pointsPerUnit: CGFloat
    let minorEveryInUnits: CGFloat
    let majorEveryInUnits: CGFloat
    let labelEveryInUnits: CGFloat
    let labelFormatter: (CGFloat) -> String

    var minorEveryInPoints: CGFloat {
        pointsPerUnit * minorEveryInUnits
    }

    var majorStep: Int {
        max(Int((majorEveryInUnits / minorEveryInUnits).rounded()), 1)
    }

    var labelStep: Int {
        max(Int((labelEveryInUnits / minorEveryInUnits).rounded()), 1)
    }
}
