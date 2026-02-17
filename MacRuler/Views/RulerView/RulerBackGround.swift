//
//  RulerBackGround.swift
//  MacRuler
//
//  Created by Eoin Kortext on 27/01/2026.
//

import SwiftUI

struct RulerBackGround : View {
    
    let rulerType:RulerType
    @Bindable var rulerSettingsViewModel: RulerSettingsViewModel
    var magnification: CGFloat = 1.0
    
    var body: some View {
         switch rulerType {
            case .vertical:
             VerticalRulerBackGround
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
                let tickConfig = rulerSettingsViewModel.unitType.tickConfiguration
                let minorEvery = tickConfig.minorEveryInPoints * max(magnification, 0.1)
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
                    for tickIndex in 0...totalTicks
                    where tickIndex.isMultiple(of: labelStep)
                        && tickIndex.isMultiple(of: majorStep)
                        && tickIndex > 0 {
                        let x = (CGFloat(tickIndex) * minorEvery)
                        let unitValue = CGFloat(tickIndex) * tickConfig.minorEveryInUnits
                        let label = tickConfig.labelFormatter(unitValue)
                        let labelSize = Constants.approximateLabelSize(
                                text: label,
                                fontSize: 9,
                                screenScale: Constants.screenScale
                        )
                        let delta = labelSize.width / 2.0
                        context.draw(
                            Text(label)
                                .font(labelFont)
                                .foregroundStyle(Color.black.opacity(0.7)),
                            at: CGPoint(x: x - delta , y: h * 0.1),
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

    var VerticalRulerBackGround: some View {
        ZStack {
            verticalGradient
            Canvas { context, size in
                let w = size.width
                let tickConfig = rulerSettingsViewModel.unitType.tickConfiguration
                let minorEvery = tickConfig.minorEveryInPoints * max(magnification, 0.1)
                let majorStep = tickConfig.majorStep
                let labelStep = tickConfig.labelStep
                let labelFont = Font.system(size: 9, weight: .medium)

                var minor = Path()
                var major = Path()

                let totalTicks = Int(size.height / minorEvery)
                for tickIndex in 0...totalTicks {
                    let y = CGFloat(tickIndex) * minorEvery
                    if tickIndex.isMultiple(of: majorStep) {
                        major.move(to: CGPoint(x: 0, y: y))
                        major.addLine(to: CGPoint(x: w * 0.65, y: y))
                    } else {
                        minor.move(to: CGPoint(x: 0, y: y))
                        minor.addLine(to: CGPoint(x: w * 0.4, y: y))
                    }
                }

                context.stroke(minor, with: .color(.black.opacity(0.35)), lineWidth: 1)
                context.stroke(major, with: .color(.black.opacity(0.65)), lineWidth: 1.2)

                if labelStep > 0 {
                    for tickIndex in 0...totalTicks
                    where tickIndex.isMultiple(of: labelStep)
                        && tickIndex.isMultiple(of: majorStep)
                        && tickIndex > 0 {
                        let y = CGFloat(tickIndex) * minorEvery
                        let unitValue = CGFloat(tickIndex) * tickConfig.minorEveryInUnits
                        let label = tickConfig.labelFormatter(unitValue)
                        let labelSize = Constants.approximateLabelSize(
                            text: label,
                            fontSize: 9,
                            screenScale: Constants.screenScale
                        )
                        context.draw(
                            Text(label)
                                .font(labelFont)
                                .foregroundStyle(Color.black.opacity(0.7)),
                            at: CGPoint(x: 2, y: y - (labelSize.height / 2.0)),
                            anchor: .topLeading
                        )
                    }
                }

                var base = Path()
                base.move(to: CGPoint(x: 0, y: 0))
                base.addLine(to: CGPoint(x: 0, y: size.height))
                context.stroke(base, with: .color(.black.opacity(0.35)), lineWidth: 1)
            }
            .padding(.horizontal, -1)
            .padding(.vertical, -1)
        }
    }
    
    var horizontalGradient: some View {
        LinearGradient(
            stops: [
                .init(color: Color.brandPrimary.opacity(0.7), location: 0.0),
                .init(color: Color.brandPrimary.opacity(0.85), location: 0.55),
                .init(color: Color.brandPrimary, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var verticalGradient: some View {
        LinearGradient(
            stops: [
                .init(color: Color.brandPrimary, location: 0.0),
                .init(color: Color.brandPrimary.opacity(0.85), location: 0.45),
                .init(color: Color.brandPrimary.opacity(0.7), location: 1.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
