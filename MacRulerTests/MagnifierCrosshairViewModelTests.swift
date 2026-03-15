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

        viewModel.resetSecondary()
        XCTAssertEqual(viewModel.primaryOffset, CGSize(width: 20, height: -10))
        XCTAssertEqual(viewModel.secondaryOffset, MagnifierCrosshairViewModel.defaultSecondaryOffset)

        viewModel.primaryOffset = CGSize(width: 11, height: 9)
        viewModel.secondaryOffset = CGSize(width: -3, height: 8)
        viewModel.resetAll()

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

    @MainActor
    func testLockStateDefaultsAndResetPrimary() {
        let viewModel = MagnifierCrosshairViewModel(
            primaryOffset: CGSize(width: 14, height: -6),
            secondaryOffset: CGSize(width: 32, height: 12)
        )

        XCTAssertFalse(viewModel.isPrimaryLocked)
        XCTAssertFalse(viewModel.isSecondaryLocked)

        viewModel.isPrimaryLocked = true
        viewModel.isSecondaryLocked = true
        viewModel.resetPrimary()

        XCTAssertEqual(viewModel.primaryOffset, .zero)
        XCTAssertEqual(viewModel.secondaryOffset, CGSize(width: 32, height: 12))
        XCTAssertTrue(viewModel.isPrimaryLocked)
        XCTAssertTrue(viewModel.isSecondaryLocked)
    }


    @MainActor
    func testNudgeSelectedCrosshairMovesPrimaryAndSecondaryBySelectionAndLockState() {
        let viewModel = MagnifierCrosshairViewModel(
            primaryOffset: .zero,
            secondaryOffset: CGSize(width: 24, height: 24)
        )

        viewModel.selectedCrosshair = .primary
        viewModel.nudgeSelectedCrosshair(x: 1, y: -1, showSecondaryCrosshair: true)
        XCTAssertEqual(viewModel.primaryOffset, CGSize(width: 1, height: -1))
        XCTAssertEqual(viewModel.secondaryOffset, CGSize(width: 24, height: 24))

        viewModel.selectedCrosshair = .secondary
        viewModel.nudgeSelectedCrosshair(x: 10, y: 0, showSecondaryCrosshair: true)
        XCTAssertEqual(viewModel.secondaryOffset, CGSize(width: 34, height: 24))

        viewModel.isSecondaryLocked = true
        viewModel.nudgeSelectedCrosshair(x: 1, y: 1, showSecondaryCrosshair: true)
        XCTAssertEqual(viewModel.secondaryOffset, CGSize(width: 34, height: 24))

        viewModel.selectedCrosshair = .secondary
        viewModel.nudgeSelectedCrosshair(x: 2, y: 3, showSecondaryCrosshair: false)
        XCTAssertEqual(viewModel.primaryOffset, CGSize(width: 3, height: 2))
    }


    @MainActor
    func testInitLoadsDefaultsWithoutRulerSettingsDependency() {
        let defaults = InMemoryDefaultsStore()
        defaults.set(false, forKey: PersistenceKeys.magnifierCrosshairEnabled)
        defaults.set(true, forKey: PersistenceKeys.magnifierSecondaryCrosshairEnabled)
        defaults.set(false, forKey: PersistenceKeys.magnifierPixelGridEnabled)
        defaults.set(9.0, forKey: PersistenceKeys.magnifierCrosshairLineWidth)
        defaults.set(MagnifierCrosshairColor.cyan.rawValue, forKey: PersistenceKeys.magnifierCrosshairColor)
        defaults.set(false, forKey: PersistenceKeys.magnifierCrosshairDualStrokeEnabled)
        defaults.set(UnitTypes.mm.rawValue, forKey: PersistenceKeys.unitType)
        defaults.set(true, forKey: PersistenceKeys.magnifierReadoutCenterPixelEnabled)
        defaults.set(true, forKey: PersistenceKeys.magnifierReadoutConvertedCoordinatesEnabled)
        defaults.set(true, forKey: PersistenceKeys.magnifierReadoutColorEnabled)
        defaults.set(true, forKey: PersistenceKeys.magnifierReadoutSecondaryReadoutsEnabled)
        defaults.set(MeasurementScaleMode.manual.rawValue, forKey: PersistenceKeys.measurementScaleMode)
        defaults.set(5.0, forKey: PersistenceKeys.measurementScaleManualValue)
        defaults.set(true, forKey: PersistenceKeys.measurementScaleBadgeEnabled)
        defaults.set(MagnifierColorOutputFormat.hsl.rawValue, forKey: PersistenceKeys.magnifierColorOutputFormat)

        let viewModel = MagnifierCrosshairViewModel(
            primaryOffset: .zero,
            secondaryOffset: MagnifierCrosshairViewModel.defaultSecondaryOffset,
            defaults: defaults
        )

        XCTAssertFalse(viewModel.showCrosshair)
        XCTAssertTrue(viewModel.showSecondaryCrosshair)
        XCTAssertFalse(viewModel.showPixelGrid)
        XCTAssertEqual(viewModel.crosshairLineWidth, 5.0)
        XCTAssertEqual(viewModel.crosshairColor, .cyan)
        XCTAssertFalse(viewModel.crosshairDualStrokeEnabled)
        XCTAssertEqual(viewModel.unitType, .mm)
        XCTAssertTrue(viewModel.showCenterPixelCoordinates)
        XCTAssertTrue(viewModel.showConvertedCenterCoordinates)
        XCTAssertTrue(viewModel.showColorValues)
        XCTAssertTrue(viewModel.showSecondaryReadouts)
        XCTAssertEqual(viewModel.measurementScaleMode, .manual)
        XCTAssertEqual(viewModel.manualMeasurementScale, 4.0)
        XCTAssertTrue(viewModel.shouldShowMeasurementScaleOverride)
        XCTAssertEqual(viewModel.selectedColorOutputFormat, .hsl)
    }

    @MainActor
    func testDidSetPersistsLocalMagnifierSettings() {
        let defaults = InMemoryDefaultsStore()
        let viewModel = MagnifierCrosshairViewModel(
            secondaryOffset: MagnifierCrosshairViewModel.defaultSecondaryOffset,
            defaults: defaults
        )

        viewModel.showPixelGrid = false
        viewModel.crosshairLineWidth = 0.1
        viewModel.crosshairColor = .red
        viewModel.crosshairDualStrokeEnabled = false
        viewModel.unitType = .inches
        viewModel.showCenterPixelCoordinates = true
        viewModel.showConvertedCenterCoordinates = true
        viewModel.showColorValues = true
        viewModel.showSecondaryReadouts = true
        viewModel.measurementScaleMode = .manual
        viewModel.manualMeasurementScale = 10
        viewModel.showMeasurementScaleOverrideBadge = true
        viewModel.selectedColorOutputFormat = .rgb

        XCTAssertEqual(defaults.object(forKey: PersistenceKeys.magnifierPixelGridEnabled) as? Bool, false)
        XCTAssertEqual(defaults.double(forKey: PersistenceKeys.magnifierCrosshairLineWidth), 0.5)
        XCTAssertEqual(defaults.string(forKey: PersistenceKeys.magnifierCrosshairColor), MagnifierCrosshairColor.red.rawValue)
        XCTAssertEqual(defaults.object(forKey: PersistenceKeys.magnifierCrosshairDualStrokeEnabled) as? Bool, false)
        XCTAssertEqual(defaults.string(forKey: PersistenceKeys.unitType), UnitTypes.inches.rawValue)
        XCTAssertEqual(defaults.object(forKey: PersistenceKeys.magnifierReadoutCenterPixelEnabled) as? Bool, true)
        XCTAssertEqual(defaults.object(forKey: PersistenceKeys.magnifierReadoutConvertedCoordinatesEnabled) as? Bool, true)
        XCTAssertEqual(defaults.object(forKey: PersistenceKeys.magnifierReadoutColorEnabled) as? Bool, true)
        XCTAssertEqual(defaults.object(forKey: PersistenceKeys.magnifierReadoutSecondaryReadoutsEnabled) as? Bool, true)
        XCTAssertEqual(defaults.string(forKey: PersistenceKeys.measurementScaleMode), MeasurementScaleMode.manual.rawValue)
        XCTAssertEqual(defaults.double(forKey: PersistenceKeys.measurementScaleManualValue), 4.0)
        XCTAssertEqual(defaults.object(forKey: PersistenceKeys.measurementScaleBadgeEnabled) as? Bool, true)
        XCTAssertEqual(defaults.string(forKey: PersistenceKeys.magnifierColorOutputFormat), MagnifierColorOutputFormat.rgb.rawValue)
    }

}
