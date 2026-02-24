# MacRuler Project Structure Guide

## Project overview

**MacRuler** is a SwiftUI macOS ruler and pixel-inspection app. It creates floating ruler windows, supports overlay dividers, and includes a screen-selection magnifier workflow so users can measure and inspect points, millimeters, centimeters, and inches.

At runtime, the app is coordinated by the `AppDelegate` and dependency container, while feature-specific `@Observable` view models drive SwiftUI views. The model layer provides units, tick configuration, readout formatting, and selection state. AppKit bridge files are used where window/frame behavior and ScreenCaptureKit integration are required.

---

## How the codebase is organized

- `MacRuler/` — app source files.
- `MacRulerTests/` — unit tests for measurement/unit logic and settings behavior.
- `docs/` — project documentation and contributor notes.

Within `MacRuler/`, folders map to responsibilities:

- **App entry + global coordination**: `MacRulerApp.swift`, `Globals/`.
- **Feature state / logic**: `ViewModels/`, `Models/`, `DividerRangeModel.swift`.
- **UI composition**: `Views/`, `Settings/`, `Toolbar/`, `Modifiers/`, `Extensions/`.
- **macOS integration**: `AppKit Interaction/`, `Delegates/`, `ScreenCapture/`, `Notifications/`.
- **Persistence/constants**: `Persistence/`, `Debug/`.

---

## Struct and class roles by type

### SwiftUI `View` structs
These structs render interface and bind to `@Observable` state.

- Ruler rendering: `HorizontalRulerView`, `VerticalRulerView`, `RulerBackGround`, `RulerLocked`, overlay ruler views.
- Readouts: `HorizontalPixelReadout`, `VerticalPixelReadout`, `CenterSampleReadoutCapsule`.
- Selection flow UI: `ScreenSelectionOverlayView`, `ScreenSelectionMagnifierView`, `SelectionMagnifierContentView`, `PixelGridOverlayView`, `SelectionHintView`.
- Settings/toolbar surfaces: `SettingsView`, `SelectionWindowToolbar`.
- AppKit bridge views that conform to `NSViewRepresentable`: `WindowScaleReader`, `RulerFrameReader`.

### `@Observable` reference types (`final class`)
These are app/view models and shared mutable state living on `@MainActor`.

- `RulerSettingsViewModel` — user-configurable behavior (units, scale mode, precision/background settings).
- `MagnificationViewModel` — magnification stepping and clamping.
- `OverlayViewModel` / `OverlayVerticalViewModel` — divider movement/normalization for overlay rulers.
- `StreamCaptureObserver` — screen stream state and sampled image pipeline for magnifier.
- `SelectionSession` — active selection data used by the magnifier overlay.
- `DebugSettingsModel` — debug-only toggles.
- `DividerRangeModel` — generic divider-range behavior shared by handles.

### Model/value structs
These represent domain values and formatting utilities.

- `TickConfiguration` — major/minor/label tick spacing and formatting rules.
- `CenterSampleReadout` — center-pixel location and RGB readout payload.
- `ReadoutDisplayComponents` + `ReadoutDisplayHelper` — formatted text assembly for readouts.

### Enums
These define app modes, units, handles, and key directions.

- Measurement + appearance: `MeasurementScaleMode`, `RulerBackgroundSize`.
- Units/ruler domain: `UnitTypes`, `RulerType`, `RulerAttachmentType`.
- Divider semantics: `DividerHandle`, `VerticalDividerHandle`, `DividerStep`.
- Keyboard nudging: `DividerKeyDirection`.

### AppKit / integration classes
These classes integrate with macOS windowing and capture APIs.

- `AppDelegate` — app lifecycle, menu actions, ruler window creation/visibility/locking, selection-mode transitions.
- `AppDependencies` — central object graph for shared app state.
- `CaptureController` — ScreenCaptureKit start/stop/config and picker delegate handling.
- `MagnifierWindowDelegate`, `HorizontalRulerWindowDelegate`, `FrameReportingView` — window/frame lifecycle helpers.
- `DividerKeyNotification` — typed wrapper for divider key movement notifications.

### Persistence helpers
- `PersistenceKeys` — namespaced `UserDefaults` keys.
- `DefaultsStoring` protocol + `InMemoryDefaultsStore` — storage abstraction and test double.
- `Constants` — global constants (window sizing, defaults, limits).

---

## File-by-file guide

### App bootstrap and global coordination
- `MacRuler/MacRulerApp.swift` — SwiftUI app entry point that wires `AppDelegate` through `NSApplicationDelegateAdaptor`.
- `MacRuler/Globals/AppDelegate.swift` — central coordinator for windows, menu commands, selection flow, and ruler positioning.
- `MacRuler/Globals/AppDependencies.swift` — constructs and holds long-lived shared models/view models.

### View models and state containers
- `MacRuler/ViewModels/RulerSettingsViewModel.swift` — stores selected units, measurement scale mode/manual scale, precision, and background size preferences; persists values.
- `MacRuler/ViewModels/MagnificationViewModel.swift` — provides normalized magnification and step-based increment/decrement logic.
- `MacRuler/ViewModels/OverlayViewModel.swift` — horizontal divider state updates with bounds and snapping behavior.
- `MacRuler/ViewModels/OverlayVerticalViewModel.swift` — vertical divider state updates with bounds and snapping behavior.
- `MacRuler/DividerRangeModel.swift` — reusable generic divider-range logic for start/end markers.
- `MacRuler/Models/SelectionSession.swift` — observable selection lifecycle model used while choosing a capture region.
- `MacRuler/Debug/DebugSettingsModel.swift` — debug toggles exposed to aid development/testing.

### Models and enum domain
- `MacRuler/Models/Enums/UnitTypes.swift` — supported measurement units and unit metadata identifiers.
- `MacRuler/Models/UnitType+Configuration.swift` — per-unit tick configuration and distance formatting behavior.
- `MacRuler/Models/TickConfiguration.swift` — tick spacing/label strategy data for ruler drawing.
- `MacRuler/Models/ReadoutDisplayHelper.swift` — builds composed readout strings and optional scale badge text.
- `MacRuler/Models/CenterSampleReadout.swift` — creates center sample coordinates and RGB content from capture buffers.
- `MacRuler/Models/Enums/RulerType.swift` — ruler orientation/attachment categorization.
- `MacRuler/Models/Enums/DividerHandle.swift` — horizontal divider handle identity.
- `MacRuler/Models/VerticalDividerHandle.swift` — vertical divider handle identity.
- `MacRuler/Models/Enums/DividerStep.swift` — keyboard/divider movement step sizes.

### Views (rulers, overlays, readouts, selection)
- `MacRuler/Views/RulerView/HorizontalRulerView.swift` — draws horizontal ticks/labels/dividers and binds to ruler state.
- `MacRuler/Views/RulerView/VerticalRulerView.swift` — vertical counterpart for ruler rendering.
- `MacRuler/Views/RulerView/OverlayHorizontalRulerView.swift` — horizontal overlay ruler container for selection mode.
- `MacRuler/Views/RulerView/OverlayVerticalRulerView.swift` — vertical overlay ruler container for selection mode.
- `MacRuler/Views/RulerView/RulerBackGround.swift` — reusable ruler background surface.
- `MacRuler/Views/RulerView/RulerLocked.swift` — lock-state indicator view.
- `MacRuler/Views/Readouts/HorizontalPixelReadout.swift` — horizontal distance readout UI.
- `MacRuler/Views/Readouts/VerticalPixelReadout.swift` — vertical distance readout UI.
- `MacRuler/Views/Screen Selection/ScreenSelectionOverlayView.swift` — full selection overlay shell.
- `MacRuler/Views/Screen Selection/ScreenSelectionMagnifierView.swift` — magnifier host views for selection mode.
- `MacRuler/Views/Screen Selection/SelectionMagnifierContentView.swift` — magnifier inner content and composition.
- `MacRuler/Views/Screen Selection/PixelGridOverlayView.swift` — pixel grid layer and frame tracking helpers.
- `MacRuler/Views/Screen Selection/CenterSampleReadoutCapsuleView.swift` — capsule-styled center sample readout.
- `MacRuler/Views/WindowView/SelectionHintView.swift` — instructional hint view for selection interactions.
- `MacRuler/Settings/SettingsView.swift` — app settings panel UI.
- `MacRuler/Toolbar/SelectionWindowToolbar.swift` — toolbar controls for the selection window.

### Screen capture and macOS integration
- `MacRuler/ScreenCapture/CaptureController.swift` — manages ScreenCaptureKit picker, stream configuration, and lifecycle callbacks.
- `MacRuler/ScreenCapture/ScreenCaptureMagnifier.swift` — stream output observer and magnifier image pipeline; includes `RulerMagnifierView`.
- `MacRuler/AppKit Interaction/WindowScaleReader.swift` — reads window backing scale/frame into SwiftUI bindings and persists horizontal ruler width.
- `MacRuler/AppKit Interaction/RulerFrameReader.swift` — reports window/view frames for alignment and positioning.
- `MacRuler/Delegates/MagnifierWindowDelegate.swift` — window delegate hooks for magnifier lifecycle.
- `MacRuler/Notifications/DividerKeyInput.swift` — keyboard notification payload for divider movement.

### Persistence, styling, and support
- `MacRuler/Persistence/PersistenceKeys.swift` — authoritative list of persisted defaults keys.
- `MacRuler/Persistence/DefaultsStore.swift` — abstraction over defaults storage plus in-memory test implementation.
- `MacRuler/Persistence/Constants.swift` — shared constants for limits/sizes and app defaults.
- `MacRuler/Extensions/Color+Extension.swift` — app color conveniences.
- `MacRuler/Modifiers/TextModifier.swift` — reusable text styling modifiers for pixel readouts.

### Tests
- `MacRulerTests/UnitTypeConfigurationTests.swift` — verifies tick configuration ratios, settings defaults/persistence, and measurement scale behavior.
- `MacRulerTests/UnitTypeFormattingTests.swift` — verifies unit names/symbols and formatted distance/readout output.

---

## End-to-end flow summary

1. `MacOSRulerApp` launches and installs `AppDelegate`.
2. `AppDependencies` builds shared observable models.
3. Ruler/overlay SwiftUI views render using view-model state and unit/tick model helpers.
4. Selection mode uses `CaptureController` + `StreamCaptureObserver` to receive captured frames.
5. Readout/model helpers convert raw measurements to user-facing strings.
6. Settings and window interactions persist values through `PersistenceKeys` and `DefaultsStoring`.
