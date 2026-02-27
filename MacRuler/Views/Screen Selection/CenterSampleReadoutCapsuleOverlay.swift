//
//  CenterSampleReadoutCapsuleOverlay.swift
//  MacRuler
//

import SwiftUI
import CoreGraphics

struct CenterSampleReadoutCapsuleOverlay: View {
    let frameImage: CGImage
    let viewportSize: CGSize
    let contentFrame: CGRect
    let magnification: CGFloat
    let readoutComposition: MagnifierReadoutComposition
    let auxiliaryReadouts: [String]

    let unitType: UnitTypes
    let measurementScale: Double
    let sourceScreenScale: Double

    var body: some View {
        let sampleReadout = CenterSampleReadout.make(
            frameImage: frameImage,
            viewportSize: viewportSize,
            contentFrame: contentFrame,
            magnification: magnification,
            screenScale: sourceScreenScale
        )

        if let sampleReadout {
            CenterSampleReadoutCapsule(
                sampleReadout: sampleReadout,
                primaryReadouts: readoutComposition.primaryReadouts,
                secondaryReadouts: readoutComposition.secondaryReadouts,
                auxiliaryReadouts: auxiliaryReadouts,
                unitType: unitType,
                measurementScale: measurementScale,
                sourceScreenScale: sourceScreenScale
            )
        } else {
            EmptyView()
        }
    }
}
