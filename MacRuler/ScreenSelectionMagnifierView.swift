//
//  ScreenSelectionMagnifierView.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-01.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ScreenSelectionMagnifierView: View {
    @Bindable var session: SelectionSession
    @State private var controller = RulerMagnifierController()

    var body: some View {
        VStack(spacing: 10) {
            SelectionWindowToolbar(
                session: session,
                snapshotAction: takeSnapshot,
                canTakeSnapshot: controller.frameImage != nil
            )
            SelectionMagnifierContentView(session: session, controller: controller)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(12)
    }

    private func takeSnapshot() {
        guard let frameImage = controller.frameImage else { return }

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "selection-snapshot.png"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let imageRep = NSBitmapImageRep(cgImage: frameImage)
        guard let data = imageRep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: url)
    }
}
