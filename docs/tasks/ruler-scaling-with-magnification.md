# Development Task: Update Ruler Scaling Behavior for Magnification

## Background
The ruler is displayed over magnified content, but its visual spacing should reflect the current magnification so the ruler appearance matches the zoomed coordinate space.

## Problem Statement
When magnification changes, ruler visuals should scale proportionally:
- Tick marks should be spaced farther apart at higher magnification (for example, 2x magnification should render tick spacing at 2x the normal visual distance).
- Drag/end handles should also move farther apart visually by the same scale factor.

At the same time, measurement correctness must be preserved:
- The numeric value in `PixelReadout` must continue to represent true underlying image pixel distance, not zoomed on-screen distance.

## Scope
- Update ruler rendering logic so tick spacing is derived from a base spacing multiplied by current magnification.
- Update handle positioning logic so visual handle separation scales with current magnification.
- Keep measurement computation in image-space pixels so readout values are invariant across zoom levels for identical underlying image points.

## Out of Scope
- Changes to non-ruler UI styling unrelated to magnification behavior.
- Unit conversion behavior beyond ensuring pixel correctness in `PixelReadout`.

## Acceptance Criteria
1. **Tick spacing scales with magnification**
   - Given ruler magnification of 1x and 2x,
   - When rendering equivalent ruler intervals,
   - Then spacing between adjacent tick marks at 2x is visually 2x the spacing at 1x.
   - And spacing scales proportionally for other magnification levels.

2. **Handle spacing scales with magnification**
   - Given the same two underlying image points,
   - When magnification changes from 1x to 2x,
   - Then the visual distance between ruler drag/end handles doubles on screen.
   - And the same proportional behavior applies across magnification levels.

3. **PixelReadout remains measurement-correct across zoom levels**
   - Given two fixed image points A and B,
   - When measured at 1x and then at 2x,
   - Then `PixelReadout` shows the same pixel distance value at both zoom levels.
   - And the value corresponds to the true underlying image pixel distance (not scaled screen-space distance).

## Suggested Validation Approach
- Add/adjust tests for coordinate conversion and readout calculation to ensure image-space invariance.
- Perform manual verification with side-by-side checks at 1x and 2x:
  - Tick spacing ratio (2x vs 1x) is ~2.0.
  - Handle spacing ratio (2x vs 1x) is ~2.0.
  - PixelReadout value for the same image points is identical.
