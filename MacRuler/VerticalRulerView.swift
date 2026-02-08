//
//  VerticalRulerView.swift
//  MacRuler
//
//  Created by Eoin Kortext on 26/01/2026.
//

import SwiftUI

struct VerticalRulerView: View {
    @Bindable var overlayViewModel: OverlayVerticalViewModel
    @Bindable var settings: RulerSettingsViewModel
    @Bindable var debugSettings: DebugSettingsModel
    @Bindable var magnificationViewModel: MagnificationViewModel

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RulerBackGround(
                    rulerType: .vertical,
                    rulerSettingsViewModel: settings,
                    magnification: CGFloat(max(magnificationViewModel.magnification, 0.1))
                )
                .frame(width: 44.0)
                OverlayVerticalView(
                    overlayViewModel: overlayViewModel,
                    magnificationViewModel: magnificationViewModel
                )
                WindowScaleReader(
                    backingScale: $overlayViewModel.backingScale,
                    windowFrame: Binding(
                        get: { overlayViewModel.windowFrame },
                        set: { frame in
                            var adjustedFrame = frame
                            adjustedFrame.size.height = max(
                                0,
                                frame.height - Constants.verticalReadoutHeight
                            )
                            overlayViewModel.windowFrame = adjustedFrame
                        }
                    )
                )
                .frame(width: 0, height: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack {
                Spacer()
                VerticalPixelReadout(
                    overlayViewModel: overlayViewModel,
                    rulerSettingsViewModel: settings,
                    magnificationViewModel: magnificationViewModel
                )
                Spacer()
            }
            .frame(height: Constants.verticalReadoutHeight)
        }
        .onTapGesture { location in
            let magnification = CGFloat(max(magnificationViewModel.magnification, 0.1))
            withAnimation(.easeInOut(duration: 0.2)) {
                overlayViewModel.updateDividers(
                    with: location.y,
                    axisLength: overlayViewModel.windowFrame.height,
                    magnification: magnification,
                    unitType: settings.unitType
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .background(
            debugSettings.showWindowBackground
            ? Color.black.opacity(0.15)
            : Color.clear
        )
        .padding(6)
    }
}
