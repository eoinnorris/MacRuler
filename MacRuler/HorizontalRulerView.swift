//
//  HorizontalRulerView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//


import SwiftUI
import AppKit

struct HorizontalRulerView: View {
    @State private var overlayViewModel = OverlayViewModel()


    var body: some View {
        ZStack {
            RulerBackGround(rulerType: .horizontal)
            OverlayHorizontalView(overlayViewModel: overlayViewModel)
            PixelReadout(overlayViewModel: overlayViewModel)
            // ✅ Invisible window reader (tracks backing scale)
            WindowScaleReader(backingScale: $overlayViewModel.backingScale)
                .frame(width: 0, height: 0)
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

    final class Coordinator: NSObject, NSWindowDelegate {
        private var backingScale: Binding<CGFloat>
        private weak var window: NSWindow?

        init(backingScale: Binding<CGFloat>) {
            self.backingScale = backingScale
        }

        func attach(to window: NSWindow) {
            guard self.window !== window else { return }
            self.window = window
            window.delegate = self
            updateBackingScale(for: window)
        }

        func windowDidResize(_ notification: Notification) {
            guard let window = notification.object as? NSWindow else { return }
            updateBackingScale(for: window)
        }

        func windowDidChangeBackingProperties(_ notification: Notification) {
            guard let window = notification.object as? NSWindow else { return }
            updateBackingScale(for: window)
        }

        private func updateBackingScale(for window: NSWindow) {
            backingScale.wrappedValue = window.screen?.backingScaleFactor
                ?? NSScreen.main?.backingScaleFactor
                ?? 2.0
        }
    }
}

final class FixedHeightResizeDelegate: NSObject, NSWindowDelegate {
    let fixedHeight: CGFloat

    init(fixedHeight: CGFloat) {
        self.fixedHeight = fixedHeight
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        NSSize(width: frameSize.width, height: fixedHeight)
    }
}
