//
//  MagnifierGestureCaptureView.swift
//  MacRuler
//

import SwiftUI
import AppKit

struct MagnifierGestureCaptureView: NSViewRepresentable {
    let onMagnify: (CGFloat) -> Void
    let onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> GestureCaptureNSView {
        let view = GestureCaptureNSView()
        view.onMagnify = onMagnify
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: GestureCaptureNSView, context: Context) {
        nsView.onMagnify = onMagnify
        nsView.onScroll = onScroll
    }
}

final class GestureCaptureNSView: NSView {
    var onMagnify: ((CGFloat) -> Void)?
    var onScroll: ((CGFloat) -> Void)?

    private var magnifyMonitor: Any?
    private var scrollMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            removeMonitors()
        } else {
            installMonitorsIfNeeded()
        }
    }

    deinit {
        removeMonitors()
    }

    private func installMonitorsIfNeeded() {
        guard magnifyMonitor == nil, scrollMonitor == nil else { return }

        magnifyMonitor = NSEvent.addLocalMonitorForEvents(matching: .magnify) { [weak self] event in
            guard let self, self.shouldHandle(event: event) else { return event }
            self.onMagnify?(event.magnification)
            return nil
        }

        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, self.shouldHandle(event: event) else { return event }
            guard event.hasPreciseScrollingDeltas else { return event }
            self.onScroll?(event.scrollingDeltaY)
            return nil
        }
    }

    private func removeMonitors() {
        if let magnifyMonitor {
            NSEvent.removeMonitor(magnifyMonitor)
            self.magnifyMonitor = nil
        }

        if let scrollMonitor {
            NSEvent.removeMonitor(scrollMonitor)
            self.scrollMonitor = nil
        }
    }

    private func shouldHandle(event: NSEvent) -> Bool {
        guard let window else { return false }
        let location = convert(window.mouseLocationOutsideOfEventStream, from: nil)
        return bounds.contains(location)
    }
}
