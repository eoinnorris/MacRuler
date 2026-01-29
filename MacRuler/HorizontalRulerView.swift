//
//  HorizontalRulerView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//


import SwiftUI
import AppKit


struct HorizontalRulerView: View {
    @Bindable var overlayViewModel:OverlayViewModel
    @Bindable var settings: RulerSettingsViewModel
    @State private var rulerFrame: CGRect = .zero


    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                RulerBackGround(rulerType: .horizontal,
                                rulerSettingsViewModel: settings)
                .frame(height: 44.0)
                .background(
                    RulerFrameReader { frame in
                        Task { @MainActor in
                            rulerFrame = frame
                        }
                    }
                )
                OverlayHorizontalView(overlayViewModel: overlayViewModel)
                // ✅ Invisible window reader (tracks backing scale)
                WindowScaleReader(backingScale: $overlayViewModel.backingScale)
                    .frame(width: 0, height: 0)
                
                VStack {
                    Spacer()
                    HStack(spacing: 0) {
                        PixelReadout(overlayViewModel: overlayViewModel,
                                     rulerSettingsViewModel: settings)
                        Spacer()
                    }
                    .frame(height: 24.0)
                    .padding(.horizontal, 0)
                    .padding(.bottom,20 )
                    .background(Color.clear)
                }
               
                
            }
            .frame(maxWidth: .infinity)
            .overlay(
                RulerMagnifierView(
                    magnifierSize: 280,
                    rulerFrame: $rulerFrame
                )
            )
        }
        .onTapGesture { location in
            withAnimation(.easeInOut(duration: 0.2)) {
                overlayViewModel.updateDividers(with: location.x)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(6)
    }
}

private struct SettingsButton: View {
    var body: some View {
        Button {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black.opacity(0.85))
                .padding(6)
                .background(.white.opacity(0.35), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bridge to NSWindow resize events -> pixel width

struct WindowScaleReader: NSViewRepresentable {
    @Binding var backingScale: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(backingScale: $backingScale)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            context.coordinator.attach(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { [weak nsView] in
            guard let window = nsView?.window else { return }
            context.coordinator.attach(to: window)
        }
    }

    final class Coordinator: NSObject {
        private var backingScale: Binding<CGFloat>
        private weak var window: NSWindow?
        private var observers: [NSObjectProtocol] = []

        init(backingScale: Binding<CGFloat>) {
            self.backingScale = backingScale
        }

        func attach(to window: NSWindow) {
            guard self.window !== window else { return }
            self.window = window
            updateBackingScale(for: window)
            startObserving(window: window)
        }

        private func updateBackingScale(for window: NSWindow) {
            backingScale.wrappedValue = window.screen?.backingScaleFactor
                ?? NSScreen.main?.backingScaleFactor
                ?? 2.0
        }

        private func startObserving(window: NSWindow) {
            removeObservers()
            let center = NotificationCenter.default
            observers = [
                center.addObserver(
                    forName: NSWindow.didResizeNotification,
                    object: window,
                    queue: .main
                ) { [weak self] notification in
                    self?.handleWindowNotification(notification)
                },
                center.addObserver(
                    forName: NSWindow.didChangeBackingPropertiesNotification,
                    object: window,
                    queue: .main
                ) { [weak self] notification in
                    self?.handleWindowNotification(notification)
                }
            ]
        }

        private func handleWindowNotification(_ notification: Notification) {
            guard let window = notification.object as? NSWindow else { return }
            updateBackingScale(for: window)
        }

        private func removeObservers() {
            let center = NotificationCenter.default
            observers.forEach { center.removeObserver($0) }
            observers.removeAll()
        }

        deinit {
            removeObservers()
        }
    }
}

final class HorizontalRulerWindowDelegate: NSObject, NSWindowDelegate {
    let fixedHeight: CGFloat

    init(fixedHeight: CGFloat) {
        self.fixedHeight = fixedHeight
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        let width = frameSize.width < Constants.minHRulerWidth ? Constants.minHRulerWidth : frameSize.width
        return NSSize(width: width, height: fixedHeight + 10.0)
    }

    func windowDidResize(_ notification: Notification) {
        saveFrame(from: notification)
    }

    private func saveFrame(from notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        UserDefaults.standard.set(
            window.frame.width,
            forKey: PersistenceKeys.horizontalRulerFrame
        )
    }
}
