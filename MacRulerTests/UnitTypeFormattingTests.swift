import XCTest
@testable import MacRuler

final class UnitTypeFormattingTests: XCTestCase {

    func testUnitSymbols() {
        XCTAssertEqual(UnitTypes.pixels.unitSymbol, "pt")
        XCTAssertEqual(UnitTypes.mm.unitSymbol, "mm")
        XCTAssertEqual(UnitTypes.cm.unitSymbol, "cm")
        XCTAssertEqual(UnitTypes.inches.unitSymbol, "in")
    }

    func testDisplayNames() {
        XCTAssertEqual(UnitTypes.pixels.displayName, "Points")
        XCTAssertEqual(UnitTypes.mm.displayName, "Millimeters")
        XCTAssertEqual(UnitTypes.cm.displayName, "Centimeters")
        XCTAssertEqual(UnitTypes.inches.displayName, "Inches")
    }

    func testFormattedDistanceForPixelsRoundsToWholePoints() {
        let text = UnitTypes.pixels.formattedDistance(points: 10.6, screenScale: 2)
        XCTAssertEqual(text, "11")
    }

    func testFormattedDistanceForMillimetersUsesSingleDecimalAndScale() {
        let text = UnitTypes.mm.formattedDistance(points: 72, screenScale: 2)
        XCTAssertEqual(text, "1.4")
    }

    func testFormattedDistanceForCentimetersUsesTwoDecimalsAndScale() {
        let text = UnitTypes.cm.formattedDistance(points: 72, screenScale: 2)
        XCTAssertEqual(text, "1.27")
    }

    func testFormattedDistanceForInchesUsesTwoDecimalsAndScale() {
        let text = UnitTypes.inches.formattedDistance(points: 72, screenScale: 2)
        XCTAssertEqual(text, "0.50")
    }

    func testReadoutComponentsIncludeScaleBadgeWhenOverrideEnabled() {
        let components = ReadoutDisplayHelper.makeComponents(
            distancePoints: 72,
            unitType: .inches,
            measurementScale: 2.0,
            magnification: 1.0,
            showMeasurementScaleOverride: true
        )

        XCTAssertTrue(components.text.localizedStandardContains("Scale 2.0x"))
    }

    func testCrosshairDeltaFormattingForPixels() {
        let labels = CrosshairReadoutFormatter.makeDeltaLabels(
            primaryCrosshairOffset: CGSize(width: 0, height: 0),
            secondaryCrosshairOffset: CGSize(width: 10, height: 20),
            unitType: .pixels,
            measurementScale: 2.0,
            magnification: 1.0,
            showMeasurementScaleOverride: false
        )

        XCTAssertEqual(labels[0], "ΔX: 10 pt • 1 x")
        XCTAssertEqual(labels[1], "ΔY: 20 pt • 1 x")
    }

    func testCrosshairDeltaFormattingForMillimeters() {
        let labels = CrosshairReadoutFormatter.makeDeltaLabels(
            primaryCrosshairOffset: CGSize(width: 0, height: 0),
            secondaryCrosshairOffset: CGSize(width: 72, height: 72),
            unitType: .mm,
            measurementScale: 2.0,
            magnification: 1.0,
            showMeasurementScaleOverride: false
        )

        XCTAssertEqual(labels[0], "ΔX: 12.7 mm • 1 x")
        XCTAssertEqual(labels[1], "ΔY: 12.7 mm • 1 x")
    }

    func testCrosshairDeltaFormattingForCentimeters() {
        let labels = CrosshairReadoutFormatter.makeDeltaLabels(
            primaryCrosshairOffset: CGSize(width: 0, height: 0),
            secondaryCrosshairOffset: CGSize(width: 72, height: 72),
            unitType: .cm,
            measurementScale: 2.0,
            magnification: 1.0,
            showMeasurementScaleOverride: false
        )

        XCTAssertEqual(labels[0], "ΔX: 1.27 cm • 1 x")
        XCTAssertEqual(labels[1], "ΔY: 1.27 cm • 1 x")
    }

    func testCrosshairDeltaFormattingForInches() {
        let labels = CrosshairReadoutFormatter.makeDeltaLabels(
            primaryCrosshairOffset: CGSize(width: 0, height: 0),
            secondaryCrosshairOffset: CGSize(width: 72, height: 72),
            unitType: .inches,
            measurementScale: 2.0,
            magnification: 1.0,
            showMeasurementScaleOverride: false
        )

        XCTAssertEqual(labels[0], "ΔX: 0.50 in • 1 x")
        XCTAssertEqual(labels[1], "ΔY: 0.50 in • 1 x")
    }

}
