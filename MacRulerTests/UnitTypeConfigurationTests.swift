import XCTest
@testable import MacRuler

final class UnitTypeConfigurationTests: XCTestCase {

    func testPixelsTickConfiguration() {
        let config = UnitTypes.pixels.tickConfiguration

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
        let config = UnitTypes.mm.tickConfiguration

        XCTAssertEqual(config.pointsPerUnit, 72 / 25.4, accuracy: 0.0001)
        XCTAssertEqual(config.minorEveryInPoints, 72 / 25.4, accuracy: 0.0001)
        XCTAssertEqual(config.majorStep, 5)
        XCTAssertEqual(config.labelStep, 10)
    }

    func testCentimetersTickConfigurationUsesExpectedRatios() {
        let config = UnitTypes.cm.tickConfiguration

        XCTAssertEqual(config.pointsPerUnit, 72 / 2.54, accuracy: 0.0001)
        XCTAssertEqual(config.majorStep, 5)
        XCTAssertEqual(config.labelStep, 10)
    }

    func testInchesTickConfigurationUsesExpectedRatios() {
        let config = UnitTypes.inches.tickConfiguration

        XCTAssertEqual(config.pointsPerUnit, 72, accuracy: 0.0001)
        XCTAssertEqual(config.majorStep, 2)
        XCTAssertEqual(config.labelStep, 8)
    }

    func testRulerBackgroundSizeDefaultsToLarge() {
        let defaults = InMemoryDefaultsStore()
        let viewModel = RulerSettingsViewModel(defaults: defaults)

        XCTAssertEqual(viewModel.horizontalRulerBackgroundSize, .large)
        XCTAssertEqual(viewModel.verticalRulerBackgroundSize, .large)
        XCTAssertEqual(viewModel.horizontalBackgroundThickness, 44.0)
        XCTAssertEqual(viewModel.verticalBackgroundThickness, 44.0)
    }

    func testRulerBackgroundSizePersistsInDefaults() {
        let defaults = InMemoryDefaultsStore()
        let viewModel = RulerSettingsViewModel(defaults: defaults)

        viewModel.horizontalRulerBackgroundSize = .small
        viewModel.verticalRulerBackgroundSize = .small

        XCTAssertEqual(defaults.string(forKey: PersistenceKeys.horizontalRulerBackgroundSize), RulerBackgroundSize.small.rawValue)
        XCTAssertEqual(defaults.string(forKey: PersistenceKeys.verticalRulerBackgroundSize), RulerBackgroundSize.small.rawValue)

        let reloaded = RulerSettingsViewModel(defaults: defaults)
        XCTAssertEqual(reloaded.horizontalRulerBackgroundSize, .small)
        XCTAssertEqual(reloaded.verticalRulerBackgroundSize, .small)
        XCTAssertEqual(reloaded.horizontalBackgroundThickness, 22.0)
        XCTAssertEqual(reloaded.verticalBackgroundThickness, 22.0)
    }

}
