//
//  RulerFrameReader.swift
//  MacRuler
//
//  Created by Eoin Kortext on 30/01/2026.
//

import AppKit
import SwiftUI

struct RulerFrameReader: NSViewRepresentable {
    // viewRectOnScreen + windowFrameOnScreen + screen
    var onFrameChange: (CGRect, CGRect, NSScreen?) -> Void

    func makeNSView(context: Context) -> FrameReportingView {
        let view = FrameReportingView()
        view.onFrameChange = onFrameChange
        return view
    }

    func updateNSView(_ nsView: FrameReportingView, context: Context) {
        nsView.onFrameChange = onFrameChange
        nsView.reportFrame()
    }
}

final class FrameReportingView: NSView {
    var onFrameChange: ((CGRect, CGRect, NSScreen?) -> Void)?

    private weak var observedWindow: NSWindow?
    private var observers: [NSObjectProtocol] = []
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        reportFrame()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        
        tearDownObservers()
        observedWindow = window
        setUpObservers()
        
        reportFrame()
    }
    
    deinit {
          tearDownObservers()
      }

    override func setFrameOrigin(_ newOrigin: NSPoint) {
        super.setFrameOrigin(newOrigin)
        reportFrame()
    }

    func reportFrame() {
        guard let window else { return }

        // View rect on screen
        let rectInWindow = convert(bounds, to: nil)
        let viewRectOnScreen = window.convertToScreen(rectInWindow)

        // Window frame on screen (already screen coords)
        let windowFrameOnScreen = window.frame

        onFrameChange?(viewRectOnScreen, windowFrameOnScreen, window.screen)
    }
    
    private func setUpObservers() {
           guard let window else { return }

           let center = NotificationCenter.default

           observers.append(
               center.addObserver(
                   forName: NSWindow.didMoveNotification,
                   object: window,
                   queue: .main
               ) { [weak self] _ in
                   self?.reportFrame()
               }
           )
       }
    
    private func tearDownObservers() {
          let center = NotificationCenter.default
          observers.forEach { center.removeObserver($0) }
          observers.removeAll()
      }
}

