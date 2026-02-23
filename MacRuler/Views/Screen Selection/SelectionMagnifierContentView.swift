//
//  SelectionMagnifierContentView.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-06.
//

import SwiftUI
import CoreGraphics

struct SelectionMagnifierContentView: View {
    @Bindable var session: SelectionSession
    @Bindable var controller: StreamCaptureObserver
    @Bindable var horizontalOverlayViewModel: OverlayViewModel
    @Bindable var verticalOverlayViewModel: OverlayVerticalViewModel
    @Bindable var rulerSettingsViewModel: RulerSettingsViewModel = .shared

    var body: some View {
        ScreenSelectionMagnifierImage(
            session: session,
            controller: controller,
            horizontalOverlayViewModel: horizontalOverlayViewModel,
            verticalOverlayViewModel: verticalOverlayViewModel,
            rulerSettingsViewModel: rulerSettingsViewModel
        )
    }
}

private struct ScreenSelectionMagnifierImage: View {
    @Bindable var session: SelectionSession
    @Bindable var controller: StreamCaptureObserver
    @Bindable var horizontalOverlayViewModel: OverlayViewModel
    @Bindable var verticalOverlayViewModel: OverlayVerticalViewModel
    @Bindable var rulerSettingsViewModel: RulerSettingsViewModel
    @State private var contentFrame: CGRect = .zero
    @State private var primaryCrosshairOffset: CGSize = .zero
    @State private var secondaryCrosshairOffset: CGSize = CGSize(width: 24, height: 24)

    private var areCrosshairsEnabled: Bool {
        rulerSettingsViewModel.showMagnifierCrosshair && rulerSettingsViewModel.showMagnifierSecondaryCrosshair
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
                        let sampleReadout = CenterSampleReadout.make(
                            frameImage: frameImage,
                            viewportSize: proxy.size,
                            contentFrame: contentFrame,
                            magnification: session.magnification,
                            screenScale: Constants.screenScale
                        )
                        PixelGridOverlayView(
                            viewportSize: proxy.size,
                            contentOrigin: contentFrame.origin,
                            magnification: session.magnification,
                            screenScale: Constants.screenScale,
                            showCrosshair: rulerSettingsViewModel.showMagnifierCrosshair,
                            showSecondaryCrosshair: rulerSettingsViewModel.showMagnifierSecondaryCrosshair,
                            showPixelGrid: rulerSettingsViewModel.showMagnifierPixelGrid,
                            primaryCrosshairOffset: $primaryCrosshairOffset,
                            secondaryCrosshairOffset: $secondaryCrosshairOffset
                        )
                        .overlay(alignment: .bottomTrailing) {
                            if let sampleReadout {
                                CenterSampleReadoutCapsule(
                                    sampleReadout: sampleReadout,
                                    auxiliaryReadouts: activeReadoutLabels()
                                )
                                .padding(10)
                            }
                        }
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

                    Button("Crosshairs", systemImage: "scope") {
                        let shouldEnableCrosshairs = !areCrosshairsEnabled
                        rulerSettingsViewModel.showMagnifierCrosshair = shouldEnableCrosshairs
                        rulerSettingsViewModel.showMagnifierSecondaryCrosshair = shouldEnableCrosshairs
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .padding(6)
                    .background(areCrosshairsEnabled ? .gray.opacity(0.3) : .black.opacity(0.2), in: .circle)
                    .help("Toggle both crosshairs")
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
        .onDisappear {
            controller.stop()
        }
        .onChange(of: session.selectionRectGlobal) { _, newValue in
            controller.updateCaptureRect(centeredOn: newValue,
                                         screenBound: session.screen?.frame ?? .zero)
        }
        .onChange(of: rulerSettingsViewModel.showMagnifierCrosshair) { _, _ in
            resetCrosshairOffsets()
        }
        .onChange(of: rulerSettingsViewModel.showMagnifierSecondaryCrosshair) { _, _ in
            secondaryCrosshairOffset = CGSize(width: 24, height: 24)
        }
    }

    private func resetCrosshairOffsets() {
        primaryCrosshairOffset = .zero
        secondaryCrosshairOffset = CGSize(width: 24, height: 24)
    }

    private func activeReadoutLabels() -> [String] {
        var labels: [String] = []
        let unitType = rulerSettingsViewModel.unitType

        if session.showHorizontalRuler {
            let horizontalComponents = ReadoutDisplayHelper.makeComponents(
                distancePoints: horizontalOverlayViewModel.dividerX ?? 0,
                unitType: unitType,
                measurementScale: rulerSettingsViewModel.effectiveMeasurementScale(displayScale: horizontalOverlayViewModel.backingScale),
                magnification: session.magnification,
                showMeasurementScaleOverride: rulerSettingsViewModel.shouldShowMeasurementScaleOverride
            )
            labels.append("H:\(horizontalComponents.text)")
        }

        if session.showVerticalRuler {
            let verticalComponents = ReadoutDisplayHelper.makeComponents(
                distancePoints: verticalOverlayViewModel.dividerY ?? 0,
                unitType: unitType,
                measurementScale: rulerSettingsViewModel.effectiveMeasurementScale(displayScale: verticalOverlayViewModel.backingScale),
                magnification: session.magnification,
                showMeasurementScaleOverride: rulerSettingsViewModel.shouldShowMeasurementScaleOverride
            )
            labels.append("V:\(verticalComponents.text)")
        }

        return labels
    }
}
