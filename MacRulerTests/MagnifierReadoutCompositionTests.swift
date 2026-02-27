import XCTest
import CoreGraphics
@testable import MacRuler

final class MagnifierReadoutCompositionTests: XCTestCase {

    @MainActor
    func testSelectionSessionReadoutModeSwitchesWhenRulersAreToggled() {
        let session = SelectionSession(
            selectionRectScreen: .zero,
            selectionRectGlobal: .zero,
            screen: nil
        )

        XCTAssertEqual(session.magnifierReadoutMode, .crosshairOnly)

        session.showHorizontalRuler = true
        XCTAssertEqual(session.magnifierReadoutMode, .crosshairPlusRulers)

        session.showHorizontalRuler = false
        session.showVerticalRuler = true
        XCTAssertEqual(session.magnifierReadoutMode, .crosshairPlusRulers)
    }

    func testCrosshairOnlyModeIncludesOnlyPrimaryDeltaReadout() {
        let composition = MagnifierReadoutComposition.compose(
            mode: .crosshairOnly,
            unitType: .pixels,
            magnification: 2.0,
            showCrosshair: true,
            showSecondaryCrosshair: true,
            primaryCrosshairOffset: .zero,
            secondaryCrosshairOffset: CGSize(width: 24, height: 24),
            horizontalDistancePoints: 88,
            horizontalDisplayScale: 2.0,
            verticalDistancePoints: 44,
            verticalDisplayScale: 2.0,
            measurementScaleProvider: { _ in 2.0 },
            showMeasurementScaleOverride: false
        )

        XCTAssertEqual(composition.primaryReadouts, ["Δ: 12.0 pt × 12.0 pt"])
        XCTAssertTrue(composition.secondaryReadouts.isEmpty)
    }

    func testCrosshairPlusRulersModeIncludesPrimaryAndSecondaryReadoutsInStableOrder() {
        let composition = MagnifierReadoutComposition.compose(
            mode: .crosshairPlusRulers,
            unitType: .pixels,
            magnification: 1.0,
            showCrosshair: true,
            showSecondaryCrosshair: true,
            primaryCrosshairOffset: .zero,
            secondaryCrosshairOffset: CGSize(width: 24, height: 10),
            horizontalDistancePoints: 88,
            horizontalDisplayScale: 2.0,
            verticalDistancePoints: 44,
            verticalDisplayScale: 2.0,
            measurementScaleProvider: { _ in 2.0 },
            showMeasurementScaleOverride: false
        )

        XCTAssertEqual(composition.primaryReadouts, ["Δ: 24.0 pt × 10.0 pt"])
        XCTAssertEqual(composition.secondaryReadouts, ["H:88 pt", "V:44 pt"])
    }

    func testCrosshairPlusRulersModeWithoutCrosshairStillRetainsRulerReadouts() {
        let composition = MagnifierReadoutComposition.compose(
            mode: .crosshairPlusRulers,
            unitType: .pixels,
            magnification: 1.0,
            showCrosshair: false,
            showSecondaryCrosshair: false,
            primaryCrosshairOffset: .zero,
            secondaryCrosshairOffset: CGSize(width: 24, height: 10),
            horizontalDistancePoints: 88,
            horizontalDisplayScale: 2.0,
            verticalDistancePoints: nil,
            verticalDisplayScale: 2.0,
            measurementScaleProvider: { _ in 2.0 },
            showMeasurementScaleOverride: false
        )

        XCTAssertTrue(composition.primaryReadouts.isEmpty)
        XCTAssertEqual(composition.secondaryReadouts, ["H:88 pt"])
    }
}
