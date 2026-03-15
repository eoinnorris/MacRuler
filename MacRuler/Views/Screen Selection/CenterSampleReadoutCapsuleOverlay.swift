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
    let unitType: UnitTypes
    let measurementScale: Double
    let sourceScreenScale: Double
    let showCenterPixelCoordinates: Bool
    let showConvertedCenterCoordinates: Bool
    let showColorValues: Bool
    let showSecondaryReadouts: Bool
    @Binding var selectedColorOutputFormat: MagnifierColorOutputFormat

    var body: some View {
        let sampleReadout = CenterSampleReadout.make(
            frameImage: frameImage,
            viewportSize: viewportSize,
            contentFrame: contentFrame,
            magnification: magnification,
            screenScale: sourceScreenScale
        )

        let hasReadoutContent = !readoutComposition.primaryReadouts.isEmpty
            || (showSecondaryReadouts && !readoutComposition.secondaryReadouts.isEmpty)
            || showCenterPixelCoordinates
            || showConvertedCenterCoordinates
            || showColorValues

        if let sampleReadout, hasReadoutContent {
            CenterSampleReadoutCapsule(
                sampleReadout: sampleReadout,
                primaryReadouts: readoutComposition.primaryReadouts,
                secondaryReadouts: readoutComposition.secondaryReadouts,
                unitType: unitType,
                measurementScale: measurementScale,
                sourceScreenScale: sourceScreenScale,
                showCenterPixelCoordinates: showCenterPixelCoordinates,
                showConvertedCenterCoordinates: showConvertedCenterCoordinates,
                showColorValues: showColorValues,
                showSecondaryReadouts: showSecondaryReadouts,
                selectedColorOutputFormat: $selectedColorOutputFormat
            )
        } else {
            EmptyView()
        }
    }
}
