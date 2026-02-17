//
//  RulerLocked.swift
//  MacRuler
//
//  Created by Eoin Kortext on 17/02/2026.
//

import SwiftUI

struct RulerLocked : View{
    let rulerType: RulerType
    @Binding var isLocked: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isLocked.toggle()
            }
            Task { @MainActor in
                switch rulerType {
                case .horizontal:
                    AppDelegate.shared?.setHorizontalRulerBackgroundLocked(
                        isLocked,
                        reason: .manualToggle
                    )
                case .vertical:
                    AppDelegate.shared?.setVerticalRulerBackgroundLocked(
                        isLocked,
                        reason: .manualToggle
                    )
                }
            }
        } label: {
            Image(systemName: isLocked ? "lock.fill" : "lock.open")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isLocked ? .white : .primary)
                .padding(6)
                .background(
                    isLocked ? Color.white.opacity(0.35) : Color.white.opacity(0.35),
                    in: Circle()
                )
                .contentTransition(.symbolEffect(.replace))
                .scaleEffect(isLocked ? 1.0 : 0.92)
        }
        .buttonStyle(.plain)
        .help(isLocked ? "Unlock ruler window dragging" : "Lock ruler window dragging")
    }
}
