import XCTest
@testable import MacRuler

final class UnitTypeConfigurationTests: XCTestCase {

    func testPixelsTickConfiguration() {
        let config = UnitTyoes.pixels.tickConfiguration

        XCTAssertEqual(config.pointsPerUnit, 1)
        XCTAssertEqual(config.minorEveryInUnits, 10)
        XCTAssertEqual(config.majorEveryInUnits, 50)
        XCTAssertEqual(config.labelEveryInUnits, 200)
        XCTAssertEqual(config.minorEveryInPoints, 10)
        XCTAssertEqual(config.majorStep, 5)
        XCTAssertEqual(config.labelStep, 20)
        XCTAssertEqual(config.labelFormatter(42.4), "42")
    }

    func testMillimetersTickConfiguration() {
        let config = UnitTyoes.mm.tickConfiguration

        XCTAssertEqual(config.pointsPerUnit, 72 / 25.4, accuracy: 0.0001)
        XCTAssertEqual(config.minorEveryInPoints, 72 / 25.4, accuracy: 0.0001)
        XCTAssertEqual(config.majorStep, 5)
        XCTAssertEqual(config.labelStep, 10)
    }

    func testCentimetersTickConfigurationUsesExpectedRatios() {
        let config = UnitTyoes.cm.tickConfiguration

        XCTAssertEqual(config.pointsPerUnit, 72 / 2.54, accuracy: 0.0001)
        XCTAssertEqual(config.majorStep, 5)
        XCTAssertEqual(config.labelStep, 10)
    }

    func testInchesTickConfigurationUsesExpectedRatios() {
        let config = UnitTyoes.inches.tickConfiguration

        XCTAssertEqual(config.pointsPerUnit, 72, accuracy: 0.0001)
        XCTAssertEqual(config.majorStep, 2)
        XCTAssertEqual(config.labelStep, 8)
    }
}
