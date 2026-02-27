import XCTest
import CoreGraphics
@testable import MacRuler

final class MagnifierCrosshairViewModelTests: XCTestCase {

    @MainActor
    func testDeltaPointsAdjustAcrossMagnifications() {
        let viewModel = MagnifierCrosshairViewModel(
            primaryOffset: .zero,
            secondaryOffset: CGSize(width: 30, height: 15)
        )

        XCTAssertEqual(viewModel.deltaPoints(magnification: 1.0).width, 30, accuracy: 0.001)
        XCTAssertEqual(viewModel.deltaPoints(magnification: 1.0).height, 15, accuracy: 0.001)

        XCTAssertEqual(viewModel.deltaPoints(magnification: 2.0).width, 15, accuracy: 0.001)
        XCTAssertEqual(viewModel.deltaPoints(magnification: 2.0).height, 7.5, accuracy: 0.001)

        XCTAssertEqual(viewModel.deltaPoints(magnification: 0.05).width, 300, accuracy: 0.001)
        XCTAssertEqual(viewModel.deltaPoints(magnification: 0.05).height, 150, accuracy: 0.001)
    }

    @MainActor
    func testResetBehaviorRestoresDefaultOffsets() {
        let viewModel = MagnifierCrosshairViewModel(
            primaryOffset: CGSize(width: 20, height: -10),
            secondaryOffset: CGSize(width: -12, height: 42)
        )

        viewModel.resetSecondaryOffset()
        XCTAssertEqual(viewModel.primaryOffset, CGSize(width: 20, height: -10))
        XCTAssertEqual(viewModel.secondaryOffset, MagnifierCrosshairViewModel.defaultSecondaryOffset)

        viewModel.primaryOffset = CGSize(width: 11, height: 9)
        viewModel.secondaryOffset = CGSize(width: -3, height: 8)
        viewModel.resetAllOffsets()

        XCTAssertEqual(viewModel.primaryOffset, .zero)
        XCTAssertEqual(viewModel.secondaryOffset, MagnifierCrosshairViewModel.defaultSecondaryOffset)
    }

    @MainActor
    func testFormattedReadoutsForAllUnitTypes() {
        let viewModel = MagnifierCrosshairViewModel(
            primaryOffset: .zero,
            secondaryOffset: CGSize(width: 72, height: 72)
        )

        XCTAssertEqual(
            viewModel.formattedDeltaReadouts(
                unitType: .pixels,
                measurementScale: 2.0,
                magnification: 1.0,
                showMeasurementScaleOverride: false
            ),
            ["ΔX: 72 pt • 1 x", "ΔY: 72 pt • 1 x"]
        )

        XCTAssertEqual(
            viewModel.formattedDeltaReadouts(
                unitType: .mm,
                measurementScale: 2.0,
                magnification: 1.0,
                showMeasurementScaleOverride: false
            ),
            ["ΔX: 12.7 mm • 1 x", "ΔY: 12.7 mm • 1 x"]
        )

        XCTAssertEqual(
            viewModel.formattedDeltaReadouts(
                unitType: .cm,
                measurementScale: 2.0,
                magnification: 1.0,
                showMeasurementScaleOverride: false
            ),
            ["ΔX: 1.27 cm • 1 x", "ΔY: 1.27 cm • 1 x"]
        )

        XCTAssertEqual(
            viewModel.formattedDeltaReadouts(
                unitType: .inches,
                measurementScale: 2.0,
                magnification: 1.0,
                showMeasurementScaleOverride: false
            ),
            ["ΔX: 0.50 in • 1 x", "ΔY: 0.50 in • 1 x"]
        )
    }
}
