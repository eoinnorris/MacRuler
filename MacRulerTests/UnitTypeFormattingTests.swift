import XCTest
@testable import MacRuler

final class UnitTypeFormattingTests: XCTestCase {

    func testUnitSymbols() {
        XCTAssertEqual(UnitTyoes.pixels.unitSymbol, "pt")
        XCTAssertEqual(UnitTyoes.mm.unitSymbol, "mm")
        XCTAssertEqual(UnitTyoes.cm.unitSymbol, "cm")
        XCTAssertEqual(UnitTyoes.inches.unitSymbol, "in")
    }

    func testDisplayNames() {
        XCTAssertEqual(UnitTyoes.pixels.displayName, "Points")
        XCTAssertEqual(UnitTyoes.mm.displayName, "Millimeters")
        XCTAssertEqual(UnitTyoes.cm.displayName, "Centimeters")
        XCTAssertEqual(UnitTyoes.inches.displayName, "Inches")
    }

    func testFormattedDistanceForPixelsRoundsToWholePoints() {
        let text = UnitTyoes.pixels.formattedDistance(points: 10.6, screenScale: 2)
        XCTAssertEqual(text, "11")
    }

    func testFormattedDistanceForMillimetersUsesSingleDecimalAndScale() {
        let text = UnitTyoes.mm.formattedDistance(points: 72, screenScale: 2)
        XCTAssertEqual(text, "1.4")
    }

    func testFormattedDistanceForCentimetersUsesTwoDecimalsAndScale() {
        let text = UnitTyoes.cm.formattedDistance(points: 72, screenScale: 2)
        XCTAssertEqual(text, "1.27")
    }

    func testFormattedDistanceForInchesUsesTwoDecimalsAndScale() {
        let text = UnitTyoes.inches.formattedDistance(points: 72, screenScale: 2)
        XCTAssertEqual(text, "0.50")
    }
}
