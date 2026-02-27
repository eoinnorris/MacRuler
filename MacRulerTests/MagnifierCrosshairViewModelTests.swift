import XCTest
@testable import MacRuler

@MainActor
final class MagnifierCrosshairViewModelTests: XCTestCase {

    func testDeltaMathAcrossMagnifications() {
        let viewModel = MagnifierCrosshairViewModel()
        viewModel.primaryCrosshairOffset = CGSize(width: 10, height: 5)
        viewModel.secondaryCrosshairOffset = CGSize(width: 34, height: 29)

        let deltaAt1x = viewModel.deltaPoints(magnification: 1.0)
        XCTAssertEqual(deltaAt1x.width, 24, accuracy: 0.0001)
        XCTAssertEqual(deltaAt1x.height, 24, accuracy: 0.0001)

        let deltaAt2x = viewModel.deltaPoints(magnification: 2.0)
        XCTAssertEqual(deltaAt2x.width, 12, accuracy: 0.0001)
        XCTAssertEqual(deltaAt2x.height, 12, accuracy: 0.0001)

        let deltaAt5x = viewModel.deltaPoints(magnification: 5.0)
        XCTAssertEqual(deltaAt5x.width, 4.8, accuracy: 0.0001)
        XCTAssertEqual(deltaAt5x.height, 4.8, accuracy: 0.0001)
    }

    func testResetBehaviorRestoresDefaultOffsets() {
        let viewModel = MagnifierCrosshairViewModel()
        viewModel.primaryCrosshairOffset = CGSize(width: -8, height: 13)
        viewModel.secondaryCrosshairOffset = CGSize(width: 101, height: -32)

        viewModel.resetOffsets()

        XCTAssertEqual(viewModel.primaryCrosshairOffset, .zero)
        XCTAssertEqual(viewModel.secondaryCrosshairOffset, MagnifierCrosshairViewModel.secondaryCrosshairDefaultOffset)

        viewModel.secondaryCrosshairOffset = CGSize(width: 3, height: 4)
        viewModel.resetSecondaryOffset()
        XCTAssertEqual(viewModel.secondaryCrosshairOffset, MagnifierCrosshairViewModel.secondaryCrosshairDefaultOffset)
    }

    func testFormattedReadoutsIncludeUnitSpecificLabels() {
        let viewModel = MagnifierCrosshairViewModel()

        for unitType in UnitTypes.allCases {
            let labels = viewModel.formattedReadoutLabels(
                unitType: unitType,
                magnification: 1.0,
                showCrosshair: true,
                showSecondaryCrosshair: true,
                showHorizontalRuler: true,
                showVerticalRuler: true,
                horizontalDistancePoints: 72,
                verticalDistancePoints: 144,
                horizontalMeasurementScale: 2.0,
                verticalMeasurementScale: 2.0,
                showMeasurementScaleOverride: false
            )

            XCTAssertEqual(labels.count, 3)
            XCTAssertTrue(labels[0].hasPrefix("Δ:"))
            XCTAssertTrue(labels[1].hasPrefix("H:"))
            XCTAssertTrue(labels[2].hasPrefix("V:"))
            XCTAssertTrue(labels[1].contains(unitType.unitSymbol), "Expected horizontal readout to include \(unitType.unitSymbol)")
            XCTAssertTrue(labels[2].contains(unitType.unitSymbol), "Expected vertical readout to include \(unitType.unitSymbol)")
        }
    }
}
