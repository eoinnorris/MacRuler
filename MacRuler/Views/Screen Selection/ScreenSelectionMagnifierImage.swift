//
//  ScreenSelectionMagnifierImage.swift
//  MacRuler
//

import SwiftUI
import CoreGraphics

struct ScreenSelectionMagnifierImage: View {
    @Bindable var session: SelectionSession
    @Bindable var controller: StreamCaptureObserver
    @Bindable var edgeDetectionOverlayController: EdgeDetectionOverlayController
    @Bindable var horizontalOverlayViewModel: OverlayViewModel
    @Bindable var verticalOverlayViewModel: OverlayVerticalViewModel
    @Bindable var crosshairViewModel: MagnifierCrosshairViewModel
    @State private var contentFrame: CGRect = .zero
    @State private var gestureStartMagnification: Double?
    @State private var isDeferringOverlayForScroll = false
    @State private var overlayResetTask: Task<Void, Never>?

    private var areCrosshairsEnabled: Bool {
        crosshairViewModel.showCrosshair && crosshairViewModel.showSecondaryCrosshair
    }

    private var shouldRenderCrosshairOverlay: Bool {
        !isDeferringOverlayForScroll
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let frameImage = controller.frameImage {
                    ScrollView([.horizontal, .vertical]) {
                        let baseSize = CGSize(width: CGFloat(CGFloat(frameImage.width) / Constants.screenScale),
                                              height: CGFloat(CGFloat(frameImage.height) / Constants.screenScale))
                        let minimumMagnificationToFillWindow = max(
                            proxy.size.width / max(baseSize.width, 1),
                            proxy.size.height / max(baseSize.height, 1)
                        )
                        let magnifiedSize = CGSize(width: baseSize.width * session.magnification,
                                                   height: baseSize.height * session.magnification)
                        Image(decorative: frameImage, scale: 4.0)
                            .resizable()
                            .frame(width: magnifiedSize.width, height: magnifiedSize.height)
                            .frame(
                                width: max(magnifiedSize.width, proxy.size.width),
                                height: max(magnifiedSize.height, proxy.size.height),
                                alignment: .topLeading
                            )
                            .onGeometryChange(for: CGRect.self) { imageProxy in
                                imageProxy.frame(in: .named("magnifier-scroll"))
                            } action: { oldValue, newValue in
                                updateContentFrameIfNeeded(oldValue: oldValue, newValue: newValue)
                            }
                            .onAppear {
                                applyFittedMagnificationIfNeeded(
                                    viewportSize: proxy.size,
                                    frameImage: frameImage
                                )
                            }
                            .onChange(of: proxy.size) { oldViewport, newViewport in
                                guard oldViewport != newViewport else { return }
                                applyFittedMagnificationIfNeeded(
                                    viewportSize: newViewport,
                                    frameImage: frameImage
                                )
                            }
                            .onChange(of: controller.frameImage?.width) { oldWidth, newWidth in
                                guard oldWidth != newWidth else { return }
                                applyFittedMagnificationIfNeeded(
                                    viewportSize: proxy.size,
                                    frameImage: frameImage
                                )
                            }
                            .onChange(of: controller.frameImage?.height) { oldHeight, newHeight in
                                guard oldHeight != newHeight else { return }
                                applyFittedMagnificationIfNeeded(
                                    viewportSize: proxy.size,
                                    frameImage: frameImage
                                )
                            }
                            .onChange(of: minimumMagnificationToFillWindow) { oldMinimum, newMinimum in
                                guard oldMinimum != newMinimum else { return }
                                applyFittedMagnificationIfNeeded(
                                    viewportSize: proxy.size,
                                    frameImage: frameImage
                                )
                            }
                    }
                    .coordinateSpace(name: "magnifier-scroll")
                    .onScrollPhaseChange { _, newPhase in
                        if newPhase == .idle {
                           removeThenAddOverlay()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        overlayLayer(proxy: proxy, frameImage: frameImage)
                    }
                } else {
                    Color.black.opacity(0.2)
                }
                
                if !controller.isStreamLive {
                    Button("Start Capture") {
                        controller.restartCapture()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(.rect(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.7), lineWidth: 1)
            )
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 8) {
                    SlidingDrawerView(position: .bottomLeft) {
                        LeftOverlayView(controller: controller,
                                        crosshairViewModel: crosshairViewModel)
                    }
                }
                .padding(.leading, 4.0)
               
            }
            .onAppear {
                controller.updateCaptureRect(centeredOn: session.selectionRectGlobal,
                                             screenBound: session.screen?.frame ?? .zero)
            }
            .onChange(of: session.selectionRectGlobal) { oldValue, newValue in
                guard oldValue != newValue else { return }
                controller.updateCaptureRect(centeredOn: newValue,
                                             screenBound: session.screen?.frame ?? .zero)
            }
            .simultaneousGesture(
                magnificationGesture(
                    viewportSize: proxy.size,
                    frameImage: controller.frameImage
                )
            )
        }
    }


    @ViewBuilder
    private func overlayLayer(proxy: GeometryProxy, frameImage: CGImage) -> some View {
        let imageSize = CGSize(
            width: CGFloat(CGFloat(frameImage.width) / Constants.screenScale) * session.magnification,
            height: CGFloat(CGFloat(frameImage.height) / Constants.screenScale) * session.magnification
        )

        ZStack {
            PixelGridOverlayView(
                viewportSize: proxy.size,
                contentOrigin: contentFrame.origin,
                magnification: session.magnification,
                screenScale: Constants.screenScale,
                showCrosshair: shouldRenderCrosshairOverlay && crosshairViewModel.showCrosshair,
                showSecondaryCrosshair: shouldRenderCrosshairOverlay && crosshairViewModel.showSecondaryCrosshair,
                showPixelGrid: crosshairViewModel.showPixelGrid,
                crosshairLineWidth: CGFloat(crosshairViewModel.crosshairLineWidth),
                crosshairColor: crosshairViewModel.crosshairColor.swiftUIColor,
                crosshairDualStrokeEnabled: crosshairViewModel.crosshairDualStrokeEnabled,
                primaryCrosshairOffset: $crosshairViewModel.primaryOffset,
                secondaryCrosshairOffset: $crosshairViewModel.secondaryOffset,
                isPrimaryLocked: $crosshairViewModel.isPrimaryLocked,
                isSecondaryLocked: $crosshairViewModel.isSecondaryLocked,
                selectedCrosshair: $crosshairViewModel.selectedCrosshair
            )
            .allowsHitTesting(crosshairViewModel.showCrosshair && !isDeferringOverlayForScroll)

            if session.showEdgeDetectionOverlay {
                ContourOverlayView(
                    normalizedContours: edgeDetectionOverlayController.normalizedContours,
                    contentOrigin: contentFrame.origin,
                    imageSize: imageSize,
                    pathOffset: CGPoint(x: 1.1, y: 1.0),
                    magnification: session.magnification
                )
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(alignment: .bottom, spacing: 6) {
                        CenterSampleReadoutCapsuleOverlay(
                            frameImage: frameImage,
                            viewportSize: proxy.size,
                            contentFrame: contentFrame,
                            magnification: session.magnification,
                            readoutComposition: readoutComposition(),
                            unitType: crosshairViewModel.unitType,
                            measurementScale: crosshairViewModel.effectiveMeasurementScale(displayScale: Constants.screenScale,sourceCaptureScale: Constants.screenScale),
                            sourceScreenScale: Constants.screenScale,
                            showCenterPixelCoordinates: crosshairViewModel.showCenterPixelCoordinates,
                            showConvertedCenterCoordinates: crosshairViewModel.showConvertedCenterCoordinates,
                            showColorValues: crosshairViewModel.showColorValues,
                            showSecondaryReadouts: crosshairViewModel.showSecondaryReadouts
                        )

                        InfoReadoutSettingsMenu(crosshairViewModel: crosshairViewModel)
                    }
                    .padding(10)
                }
            }
        }
    }

    private func imageOriginInScrollView(
        viewportSize: CGSize,
        magnifiedImageSize: CGSize,
        trackedContentFrame: CGRect
    ) -> CGPoint {
        let insetX = max(0, (viewportSize.width - magnifiedImageSize.width) / 2)
        let insetY = max(0, (viewportSize.height - magnifiedImageSize.height) / 2)

        return CGPoint(
            x: trackedContentFrame.minX + insetX,
            y: trackedContentFrame.minY + insetY
        )
    }


    private func readoutComposition() -> MagnifierReadoutComposition {
        MagnifierReadoutComposition.compose(
            mode: session.magnifierReadoutMode,
            unitType: crosshairViewModel.unitType,
            magnification: session.magnification,
            sourceDisplayScale: Constants.screenScale,
            showCrosshair: crosshairViewModel.showCrosshair,
            showSecondaryCrosshair: crosshairViewModel.showSecondaryCrosshair,
            primaryCrosshairOffset: crosshairViewModel.primaryOffset,
            secondaryCrosshairOffset: crosshairViewModel.secondaryOffset,
            horizontalDistancePoints: session.showHorizontalRuler ? horizontalOverlayViewModel.dividerX : nil,
            horizontalDisplayScale: horizontalOverlayViewModel.backingScale,
            verticalDistancePoints: session.showVerticalRuler ? verticalOverlayViewModel.dividerY : nil,
            verticalDisplayScale: verticalOverlayViewModel.backingScale,
            measurementScaleProvider: { displayScale in
                crosshairViewModel.effectiveMeasurementScale(displayScale: displayScale, sourceCaptureScale: Constants.screenScale)
            },
            showMeasurementScaleOverride: crosshairViewModel.shouldShowMeasurementScaleOverride
        )
    }

    private func applyFittedMagnificationIfNeeded(viewportSize: CGSize, frameImage: CGImage) {
        let clampedMagnification = minimumFittedMagnification(
            viewportSize: viewportSize,
            frameImage: frameImage
        )

        if session.magnification < clampedMagnification {
            session.magnification = clampedMagnification
        }
    }

    private func minimumFittedMagnification(viewportSize: CGSize, frameImage: CGImage) -> Double {
        let baseSize = CGSize(
            width: CGFloat(CGFloat(frameImage.width) / Constants.screenScale),
            height: CGFloat(CGFloat(frameImage.height) / Constants.screenScale)
        )

        guard baseSize.width > 0, baseSize.height > 0 else {
            return MagnificationViewModel.minimumMagnification
        }

        let magnificationNeededToFillWindow = max(
            viewportSize.width / baseSize.width,
            viewportSize.height / baseSize.height
        )

        return min(
            max(magnificationNeededToFillWindow, MagnificationViewModel.minimumMagnification),
            MagnificationViewModel.maximumMagnification
        )
    }

    private func updateContentFrameIfNeeded(oldValue: CGRect, newValue: CGRect) {
        guard !oldValue.isApproximatelyEqual(to: newValue, tolerance: 0.5) else { return }
        guard !contentFrame.isApproximatelyEqual(to: newValue, tolerance: 0.5) else { return }
        contentFrame = newValue
    }

    private func magnificationGesture(viewportSize: CGSize, frameImage: CGImage?) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if gestureStartMagnification == nil {
                    gestureStartMagnification = session.magnification
                }

                guard let gestureStartMagnification else { return }
                let proposedMagnification = gestureStartMagnification * value.magnification
                let minimumMagnification = if let frameImage {
                    minimumFittedMagnification(
                        viewportSize: viewportSize,
                        frameImage: frameImage
                    )
                } else {
                    MagnificationViewModel.minimumMagnification
                }
                session.magnification = min(
                    max(proposedMagnification, minimumMagnification),
                    MagnificationViewModel.maximumMagnification
                )
                isDeferringOverlayForScroll = true
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2))
                    isDeferringOverlayForScroll = false
                }
            }
            .onEnded { _ in
                gestureStartMagnification = nil
            }
    }
    

    private func removeThenAddOverlay() {
        isDeferringOverlayForScroll = true

        overlayResetTask?.cancel()

        overlayResetTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(2))
                isDeferringOverlayForScroll = false
            } catch {
                // cancelled — ignore
            }
        }
    }
}

private extension CGRect {
    func isApproximatelyEqual(to other: CGRect, tolerance: CGFloat) -> Bool {
        abs(origin.x - other.origin.x) <= tolerance &&
        abs(origin.y - other.origin.y) <= tolerance &&
        abs(size.width - other.size.width) <= tolerance &&
        abs(size.height - other.size.height) <= tolerance
    }
}

private struct InfoReadoutSettingsMenu: View {
    @Bindable var crosshairViewModel: MagnifierCrosshairViewModel

    var body: some View {
        Menu {
            Toggle("Center coordinates", isOn: $crosshairViewModel.showCenterPixelCoordinates)
            Toggle("Converted coordinates", isOn: $crosshairViewModel.showConvertedCenterCoordinates)
            Toggle("Color values", isOn: $crosshairViewModel.showColorValues)
            Toggle("Secondary readouts (H/V)", isOn: $crosshairViewModel.showSecondaryReadouts)
        } label: {
            Label("Info Layout Settings", systemImage: "gearshape")
                .labelStyle(.iconOnly)
                .padding(6)
                .background(.black.opacity(0.2), in: .circle)
                .foregroundStyle(.primary)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .help("Info layout settings")
    }
}


private struct LeftOverlayView: View {
    
    @Bindable var controller: StreamCaptureObserver
    @Bindable var crosshairViewModel: MagnifierCrosshairViewModel

    
    var body: some View {
        HStack(spacing: 8) {
            Menu {
                if controller.isStreamLive {
                    Button("Pause") {
                        controller.pauseCapture()
                    }
                    Menu("Pause after…") {
                        Button("1 second") {
                            controller.pauseCapture(after: 1)
                        }
                        Button("2 seconds") {
                            controller.pauseCapture(after: 2)
                        }
                        Button("5 seconds") {
                            controller.pauseCapture(after: 5)
                        }
                    }
                } else {
                    Button("Go Live") {
                        controller.restartCapture()
                    }
                }
            } label: {
                Text(controller.isStreamLive ? "Live" : "Paused")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(controller.isStreamLive ? Color.green.opacity(0.9) : Color.orange.opacity(0.85))
                    .clipShape(.capsule)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            
            Menu {
                Button(crosshairViewModel.isPrimaryLocked ? "Unlock Primary" : "Lock Primary") {
                    crosshairViewModel.isPrimaryLocked.toggle()
                }
                .disabled(!crosshairViewModel.showCrosshair)
                
                Button(crosshairViewModel.isSecondaryLocked ? "Unlock Secondary" : "Lock Secondary") {
                    crosshairViewModel.isSecondaryLocked.toggle()
                }
                .disabled(!crosshairViewModel.showSecondaryCrosshair)
                
                Divider()
                
                Button("Reset selected") {
                    if crosshairViewModel.showSecondaryCrosshair {
                        crosshairViewModel.resetSecondary()
                    } else {
                        crosshairViewModel.resetPrimary()
                    }
                }
                
                Button("Reset all") {
                    crosshairViewModel.resetAll()
                }
                
                Divider()
                
                Button("Crosshairs", systemImage: "scope") {
                    let shouldEnableCrosshairs = !areCrosshairsEnabled
                    crosshairViewModel.showCrosshair = shouldEnableCrosshairs
                    crosshairViewModel.showSecondaryCrosshair = shouldEnableCrosshairs
                }
            } label: {
                Label("Crosshairs", systemImage: "scope")
                    .labelStyle(.iconOnly)
                    .padding(6)
                    .background(areCrosshairsEnabled ? .gray.opacity(0.3) : .black.opacity(0.2), in: .circle)
                    .foregroundStyle(areCrosshairsEnabled ? .green : .primary)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .help("Crosshair actions")
            .padding(10)
        }
    }
    
    private var areCrosshairsEnabled: Bool {
        crosshairViewModel.showCrosshair && crosshairViewModel.showSecondaryCrosshair
    }
}
