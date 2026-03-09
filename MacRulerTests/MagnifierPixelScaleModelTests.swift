import XCTest
@testable import MacRuler

final class MagnifierPixelScaleModelTests: XCTestCase {
    func testViewPointsPerSourcePixelUsesMagnificationAndScreenScale() {
        let model = MagnifierPixelScaleModel(magnification: 8.0, sourceScreenScale: 2.0)
        XCTAssertEqual(model.viewPointsPerSourcePixel, 4.0)
    }

    func testSourcePixelDistanceMatchesCenterSampleReadoutConversion() {
        let model = MagnifierPixelScaleModel(magnification: 6.0, sourceScreenScale: 2.0)
        XCTAssertEqual(model.sourcePixelDistance(forViewDistance: 15.0), 5.0)
    }

    func testSourcePixelIndexRoundsDown() {
        let model = MagnifierPixelScaleModel(magnification: 5.0, sourceScreenScale: 2.0)
        XCTAssertEqual(model.sourcePixelIndex(forViewCoordinate: 9.9), 3)
    }

    func testInitClampsUnsafeInput() {
        let model = MagnifierPixelScaleModel(magnification: 0.0, sourceScreenScale: 0.0)
        XCTAssertEqual(model.viewPointsPerSourcePixel, 1.0)
        XCTAssertEqual(model.sourcePixelDistance(forViewDistance: 2.0), 2.0)
    }
}
