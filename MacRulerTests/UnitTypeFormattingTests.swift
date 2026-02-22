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

}
