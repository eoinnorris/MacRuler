//
//  CaptureController.swift
//  MacRuler
//
//  Created by Eoin Kortext on 05/02/2026.
//


import Foundation
import ScreenCaptureKit
import CoreMedia

@MainActor
final class CaptureController: NSObject {

    // Keep references alive
    private let picker = SCContentSharingPicker.shared
    private var stream: SCStream?

    // Configure once (tweak as needed)
    private let config: SCStreamConfiguration = {
        let c = SCStreamConfiguration()
        c.capturesAudio = false
        c.captureMicrophone = false
        c.showsCursor = true
        // c.minimumFrameInterval = CMTime(value: 1, timescale: 60) // optional fps cap
        return c
    }()

    // Optional: tell SwiftUI what got picked
    var onDidUpdateFilter: ((SCContentFilter) -> Void)?
    var onDidCancel: (() -> Void)?
    var onDidFail: ((Error) -> Void)?

    func beginWindowSelection() {
        // Attach observer + activate picker
        picker.add(self)
        picker.isActive = true

        // Present system picker UI for WINDOW selection.
        // NOTE: API surface differs a bit across OS versions / platforms.
        // This is the modern call shown in Apple’s docs + WWDC material.
        picker.present(using: .application)
    }

    private func ensureStreamStarted(with filter: SCContentFilter) {
        if let stream {
            stream.updateContentFilter(filter)
            return
        }

        let newStream = SCStream(filter: filter, configuration: config, delegate: self)
        self.stream = newStream

        Task {
            do {
                try await newStream.startCapture()
            } catch {
                onDidFail?(error)
            }
        }
    }

    func stopCapture() {
        guard let stream else { return }
        Task {
            do { try await stream.stopCapture() }
            catch { onDidFail?(error) }
        }
        self.stream = nil
    }
}

// MARK: - SCContentSharingPickerObserver
extension CaptureController: SCContentSharingPickerObserver {

    // These callbacks are not guaranteed to arrive on MainActor.
    // Hop back to MainActor explicitly to keep SwiftUI + state updates safe.
    nonisolated func contentSharingPicker(_ picker: SCContentSharingPicker,
                                         didUpdateWith filter: SCContentFilter,
                                         for stream: SCStream?) {
        Task { @MainActor in
            self.onDidUpdateFilter?(filter)

            if let existing = stream {
                do {
                    try await existing.updateContentFilter(filter)
                } catch {
                    onDidFail?(error)
                }
                return
            }

            self.ensureStreamStarted(with: filter)
        }
    }

    nonisolated func contentSharingPicker(_ picker: SCContentSharingPicker,
                                         didCancelFor stream: SCStream?) {
        Task { @MainActor in
            self.onDidCancel?()
        }
    }

    nonisolated func contentSharingPickerStartDidFailWithError(_ error: any Error) {
        Task { @MainActor in
            self.onDidFail?(error)
        }
    }
}

// MARK: - SCStreamDelegate
extension CaptureController: SCStreamDelegate {
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            self.onDidFail?(error)
            self.stream = nil
        }
    }
}
