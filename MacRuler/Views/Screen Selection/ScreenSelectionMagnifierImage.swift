//
//  ScreenSelectionMagnifierImage.swift
//  MacRuler
//

import SwiftUI
import CoreGraphics

struct ScreenSelectionMagnifierImage: View {
    @Bindable var session: SelectionSession
    @Bindable var controller: StreamCaptureObserver
    @Bindable var horizontalOverlayViewModel: OverlayViewModel
    @Bindable var verticalOverlayViewModel: OverlayVerticalViewModel
    @Bindable var rulerSettingsViewModel: RulerSettingsViewModel
    @Bindable var crosshairViewModel: MagnifierCrosshairViewModel
    @State private var contentFrame: CGRect = .zero

    private var areCrosshairsEnabled: Bool {
        crosshairViewModel.showCrosshair && crosshairViewModel.showSecondaryCrosshair
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let frameImage = controller.frameImage {
                    ScrollView([.horizontal, .vertical]) {
                        let baseSize = CGSize(width: CGFloat(CGFloat(frameImage.width) / Constants.screenScale),
                                              height: CGFloat(CGFloat(frameImage.height) / Constants.screenScale))
                        let magnifiedSize = CGSize(width: baseSize.width * session.magnification,
                                                   height: baseSize.height * session.magnification)
                        Image(decorative: frameImage, scale: 4.0)
                            .resizable()
                            .frame(width: magnifiedSize.width, height: magnifiedSize.height)
                            .frame(
                                width: max(magnifiedSize.width, proxy.size.width),
                                height: max(magnifiedSize.height, proxy.size.height),
                                alignment: .center
                            )
                            .trackFrame(in: .named("magnifier-scroll"))
                    }
                    .coordinateSpace(name: "magnifier-scroll")
                    .onFrameChange { contentFrame = $0 }
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
                        .disabled(!rulerSettingsViewModel.showMagnifierCrosshair)
                        
                        Button(crosshairViewModel.isSecondaryLocked ? "Unlock Secondary" : "Lock Secondary") {
                            crosshairViewModel.isSecondaryLocked.toggle()
                        }
                        .disabled(!rulerSettingsViewModel.showMagnifierSecondaryCrosshair)
                        
                        Divider()
                        
                        Button("Reset selected") {
                            if rulerSettingsViewModel.showMagnifierSecondaryCrosshair {
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
                            rulerSettingsViewModel.showMagnifierCrosshair = shouldEnableCrosshairs
                            rulerSettingsViewModel.showMagnifierSecondaryCrosshair = shouldEnableCrosshairs
                        }
                    } label: {
                        Label("Crosshairs", systemImage: "scope")
                            .labelStyle(.iconOnly)
                            .padding(6)
                            .background(areCrosshairsEnabled ? .gray.opacity(0.3) : .black.opacity(0.2), in: .circle)
                            .foregroundStyle(areCrosshairsEnabled ? .green : .primary)
                        Button("Crosshairs", systemImage: "scope") {
                            let shouldEnableCrosshairs = !areCrosshairsEnabled
                            crosshairViewModel.showCrosshair = shouldEnableCrosshairs
                            crosshairViewModel.showSecondaryCrosshair = shouldEnableCrosshairs
                        }
                        .menuStyle(.button)
                        .buttonStyle(.plain)
                        .help("Crosshair actions")
                    }
                    .padding(10)
                }
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                )
            }
            .onAppear {
                controller.updateCaptureRect(centeredOn: session.selectionRectGlobal,
                                             screenBound: session.screen?.frame ?? .zero)
            }
            .onChange(of: session.selectionRectGlobal) { _, newValue in
                controller.updateCaptureRect(centeredOn: newValue,
                                             screenBound: session.screen?.frame ?? .zero)
            }
            .onChange(of: rulerSettingsViewModel.showMagnifierCrosshair) { _, _ in
                resetCrosshairOffsets()
            }
            .onChange(of: rulerSettingsViewModel.showMagnifierSecondaryCrosshair) { _, _ in
                crosshairViewModel.resetSecondary()
            }
        }
    }


    @ViewBuilder
    private func overlayLayer(proxy: GeometryProxy, frameImage: CGImage) -> some View {
        ZStack {
            PixelGridOverlayView(
                viewportSize: proxy.size,
                contentOrigin: contentFrame.origin,
                magnification: session.magnification,
                screenScale: Constants.screenScale,
                showCrosshair: crosshairViewModel.showCrosshair,
                showSecondaryCrosshair: crosshairViewModel.showSecondaryCrosshair,
                showPixelGrid: rulerSettingsViewModel.showMagnifierPixelGrid,
                crosshairLineWidth: CGFloat(rulerSettingsViewModel.magnifierCrosshairLineWidth),
                crosshairColor: rulerSettingsViewModel.magnifierCrosshairColor.swiftUIColor,
                crosshairDualStrokeEnabled: rulerSettingsViewModel.magnifierCrosshairDualStrokeEnabled,
                primaryCrosshairOffset: $crosshairViewModel.primaryOffset,
                secondaryCrosshairOffset: $crosshairViewModel.secondaryOffset,
                isPrimaryLocked: $crosshairViewModel.isPrimaryLocked,
                isSecondaryLocked: $crosshairViewModel.isSecondaryLocked
            )
            .allowsHitTesting(crosshairViewModel.showCrosshair)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    CenterSampleReadoutCapsuleOverlay(
                        frameImage: frameImage,
                        viewportSize: proxy.size,
                        contentFrame: contentFrame,
                        magnification: session.magnification,
                        readoutComposition: readoutComposition(),
                        unitType: rulerSettingsViewModel.unitType,
                        measurementScale: effectiveMeasurementScale(),
                        sourceScreenScale: Constants.screenScale,
                        showCenterPixelCoordinates: rulerSettingsViewModel.showMagnifierReadoutCenterPixel,
                        showConvertedCenterCoordinates: rulerSettingsViewModel.showMagnifierReadoutConvertedCoordinates,
                        showColorValues: rulerSettingsViewModel.showMagnifierReadoutColor,
                        showSecondaryReadouts: rulerSettingsViewModel.showMagnifierReadoutSecondaryReadouts
                    )
                    .padding(10)
                }
            }
        }
    }

    private func resetCrosshairOffsets() {
        crosshairViewModel.resetAll()
    }

    private func effectiveMeasurementScale(displayScale: Double = Constants.screenScale) -> Double {
        rulerSettingsViewModel.effectiveMeasurementScale(
            displayScale: displayScale,
            sourceCaptureScale: Constants.screenScale
        )
    }

    private func readoutComposition() -> MagnifierReadoutComposition {
        MagnifierReadoutComposition.compose(
            mode: session.magnifierReadoutMode,
            unitType: rulerSettingsViewModel.unitType,
            magnification: session.magnification,
            sourceDisplayScale: Constants.screenScale,
            showCrosshair: rulerSettingsViewModel.showMagnifierCrosshair,
            showSecondaryCrosshair: rulerSettingsViewModel.showMagnifierSecondaryCrosshair,
            primaryCrosshairOffset: crosshairViewModel.primaryOffset,
            secondaryCrosshairOffset: crosshairViewModel.secondaryOffset,
            horizontalDistancePoints: session.showHorizontalRuler ? horizontalOverlayViewModel.dividerX : nil,
            horizontalDisplayScale: horizontalOverlayViewModel.backingScale,
            verticalDistancePoints: session.showVerticalRuler ? verticalOverlayViewModel.dividerY : nil,
            verticalDisplayScale: verticalOverlayViewModel.backingScale,
            measurementScaleProvider: { displayScale in
                rulerSettingsViewModel.effectiveMeasurementScale(displayScale: displayScale)
            },
            showMeasurementScaleOverride: rulerSettingsViewModel.shouldShowMeasurementScaleOverride
        )
    }

}
