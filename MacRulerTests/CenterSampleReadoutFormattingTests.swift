import XCTest
@testable import MacRuler

final class CenterSampleReadoutFormattingTests: XCTestCase {
    func testNormalizedRGBFormattingIsStable() {
        let sample = CenterSampleReadout(pixelX: 0, pixelY: 0, red: 128, green: 64, blue: 255)

        XCTAssertEqual(sample.normalizedRGBLabel, "RGB(0.502, 0.251, 1.000)")
    }

    func testHSLFormattingForPrimaryColors() {
        let red = CenterSampleReadout(pixelX: 0, pixelY: 0, red: 255, green: 0, blue: 0)
        XCTAssertEqual(red.hslLabel, "HSL(0, 100%, 50%)")

        let green = CenterSampleReadout(pixelX: 0, pixelY: 0, red: 0, green: 255, blue: 0)
        XCTAssertEqual(green.hslLabel, "HSL(120, 100%, 50%)")

        let blue = CenterSampleReadout(pixelX: 0, pixelY: 0, red: 0, green: 0, blue: 255)
        XCTAssertEqual(blue.hslLabel, "HSL(240, 100%, 50%)")
    }
}
