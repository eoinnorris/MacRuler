//
//  SelectionMagnifierContentView.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-06.
//

import SwiftUI

struct SelectionMagnifierContentView: View {
    @Bindable var session: SelectionSession
    @Bindable var controller: StreamCaptureObserver

    var body: some View {
        ScreenSelectionMagnifierImage(session: session, controller: controller)
    }
}

private struct ScreenSelectionMagnifierImage: View {
    @Bindable var session: SelectionSession
    @Bindable var controller: StreamCaptureObserver

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
            .overlay(alignment: .bottomLeading) {
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
                        .background(controller.isStreamLive ? Color.green.opacity(0.8) : Color.orange.opacity(0.85))
                        .clipShape(Capsule())
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
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
    }
}
