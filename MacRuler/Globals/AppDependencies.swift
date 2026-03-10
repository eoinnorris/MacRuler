import Foundation

@MainActor
final class AppDependencies {
    /// Shared live dependencies for the app process.
    static let live = AppDependencies()

    let defaultsStore: DefaultsStoring
    let rulerSettings: RulerSettingsViewModel
    let overlay: OverlayViewModel
    let overlayVertical: OverlayVerticalViewModel
    let debugSettings: DebugSettingsModel
    let magnification: MagnificationViewModel
    let magnifierCrosshair: MagnifierCrosshairViewModel

    init(defaultsStore: DefaultsStoring = UserDefaults.standard) {
        self.defaultsStore = defaultsStore
        let rulerSettings = RulerSettingsViewModel(defaults: defaultsStore)
        let overlay = OverlayViewModel(defaults: defaultsStore)
        self.rulerSettings = rulerSettings
        self.overlay = overlay
        self.overlayVertical = OverlayVerticalViewModel(
            defaults: defaultsStore,
            horizontalOverlayViewModel: overlay,
            rulerSettings: rulerSettings
        )
        self.debugSettings = DebugSettingsModel()
        self.magnification = MagnificationViewModel()
        self.magnifierCrosshair = MagnifierCrosshairViewModel(
            secondaryOffset: MagnifierCrosshairViewModel.defaultSecondaryOffset,
            rulerSettings: rulerSettings
        )
    }
}
