//
//  HorizontalRulerView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//


import SwiftUI
import AppKit

struct HorizontalRulerView: View {
    @State private var pixelWidth: Int = 0

    var body: some View {
        ZStack {
            // ✅ Yellow gradient background
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.85),
                    Color.init(hex: "#FFBE00"),
                    Color.yellow.opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // ✅ Tick marks
            Canvas { context, size in
                let h = size.height
                let minorEvery: CGFloat = 10   // points (roughly “ticks”)
                let majorEvery: CGFloat = 50

                var minor = Path()
                var major = Path()

                var x: CGFloat = 0
                while x <= size.width {
                    if x.truncatingRemainder(dividingBy: majorEvery) == 0 {
                        major.move(to: CGPoint(x: x, y: h))
                        major.addLine(to: CGPoint(x: x, y: h * 0.35))
                    } else {
                        minor.move(to: CGPoint(x: x, y: h))
                        minor.addLine(to: CGPoint(x: x, y: h * 0.6))
                    }
                    x += minorEvery
                }

                context.stroke(minor, with: .color(.black.opacity(0.35)), lineWidth: 1)
                context.stroke(major, with: .color(.black.opacity(0.65)), lineWidth: 1.2)

                // Optional baseline
                var base = Path()
                base.move(to: CGPoint(x: 0, y: h - 1))
                base.addLine(to: CGPoint(x: size.width, y: h - 1))
                context.stroke(base, with: .color(.black.opacity(0.35)), lineWidth: 1)
            }
            .padding(.horizontal, -1)
            .padding(.vertical,-1)

            // ✅ Pixel width readout (top-left)
            VStack {
                HStack {
                    Text("\(pixelWidth) px")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.black.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.35), in: Capsule())
                    Spacer()
                }
                Spacer()
            }
            .padding(10)

            // ✅ Invisible window reader (updates pixelWidth as you resize)
            WindowPixelWidthReader(pixelWidth: $pixelWidth)
                .frame(width: 0, height: 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(6)
    }
}

// MARK: - Bridge to NSWindow resize events -> pixel width

struct WindowPixelWidthReader: NSViewRepresentable {
    @Binding var pixelWidth: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(pixelWidth: $pixelWidth)
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
        private var pixelWidth: Binding<Int>
        private weak var window: NSWindow?

        init(pixelWidth: Binding<Int>) {
            self.pixelWidth = pixelWidth
        }

        func attach(to window: NSWindow) {
            guard self.window !== window else { return }
            self.window = window
            window.delegate = self
            updatePixelWidth(for: window)
        }

        func windowDidResize(_ notification: Notification) {
            guard let window = notification.object as? NSWindow else { return }
            updatePixelWidth(for: window)
        }

        func windowDidChangeBackingProperties(_ notification: Notification) {
            guard let window = notification.object as? NSWindow else { return }
            updatePixelWidth(for: window)
        }

        private func updatePixelWidth(for window: NSWindow) {
            let scale = window.screen?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
            let points = window.frame.size.width
            pixelWidth.wrappedValue = Int((points * scale).rounded())
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
