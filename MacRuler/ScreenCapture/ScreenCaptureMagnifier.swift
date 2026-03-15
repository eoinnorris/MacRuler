//
//  ScreenCaptureMagnifier.swift
//  MacRuler
//
//  Created by Eoin Kortext on 29/01/2026.
//

import AppKit
import CoreMedia
@preconcurrency import ScreenCaptureKit
import SwiftUI


private struct RulerMagnifierView: View {
    @Bindable var viewModel: MagnificationViewModel
    @State private var controller = StreamCaptureObserver()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let frameImage = controller.frameImage {
                    ScrollView([.horizontal, .vertical]) {
                        let baseSize = CGSize(width: CGFloat(CGFloat(frameImage.width) / Constants.screenScale),
                                              height: CGFloat(CGFloat(frameImage.height) / Constants.screenScale))
                        let magnifiedSize = CGSize(width: baseSize.width * viewModel.magnification,
                                                   height: baseSize.height * viewModel.magnification)
                        Image(decorative: frameImage, scale: 4.0)
                            .resizable()
                            .frame(width: magnifiedSize.width, height: magnifiedSize.height)
                            .frame(
                                width: max(magnifiedSize.width, proxy.size.width),
                                height: max(magnifiedSize.height, proxy.size.height),
                                alignment: .center
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
            )
        }
        .onAppear {
            controller.updateCaptureRect(centeredOn: viewModel.rulerWindowFrame,
                                         screenBound: viewModel.screen?.frame ?? CGRect.zero)
        }
        .onDisappear {
            controller.stop()
        }
        .onChange(of: viewModel.rulerWindowFrame) { _, newValue in
            controller.updateCaptureRect(centeredOn: newValue,
                                         screenBound: viewModel.screen?.frame ?? CGRect.zero)
        }
    }
}
