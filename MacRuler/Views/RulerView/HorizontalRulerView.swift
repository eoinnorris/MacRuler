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
    @Bindable var debugSettings: DebugSettingsModel
    @Bindable var magnificationViewModel: MagnificationViewModel


    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                VStack{
                    RulerBackGround(
                        rulerType: .horizontal,
                        rulerSettingsViewModel: settings,
                        magnification: CGFloat(max(magnificationViewModel.magnification, 0.1))
                    )
                    .frame(height: 44.0)
                    Spacer()
                }
                .background(
                    RulerFrameReader {  rulerFrame, windowFrame, screen in
                        magnificationViewModel.rulerFrame = rulerFrame
                        magnificationViewModel.rulerWindowFrame = windowFrame
                        magnificationViewModel.screen = screen
                    }
                )
                OverlayHorizontalRulerView(
                    overlayViewModel: overlayViewModel,
                    magnificationViewModel: magnificationViewModel
                )
                // ✅ Invisible window reader (tracks backing scale)
                WindowScaleReader(
                    backingScale: $overlayViewModel.backingScale,
                    windowFrame: $overlayViewModel.windowFrame
                ).frame(width: 0, height: 0)
                
                VStack {
                    Spacer()
                    HStack(spacing: 0) {
                        Spacer()
                        HorizontalPixelReadout(overlayViewModel: overlayViewModel,
                                     rulerSettingsViewModel: settings,
                                     magnificationViewModel: magnificationViewModel)
                    }
                    .frame(height: 24.0)
                    .padding(.horizontal, 0)
                    .padding(.bottom, 56.0)
                    .background(Color.clear)
                }
               
                
            }
            .frame(maxWidth: .infinity)
        }
        .gesture(
            SpatialTapGesture(count: 2)
                .onEnded { value in
                    let magnification = CGFloat(max(magnificationViewModel.magnification, 0.1))
                    withAnimation(.easeInOut(duration: 0.2)) {
                        overlayViewModel.updateDividers(
                            with: value.location.x,
                            axisLength: overlayViewModel.windowFrame.width,
                            magnification: magnification,
                            unitType: settings.unitType
                        )
                    }
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .background(
            debugSettings.showWindowBackground
            ? Color.black.opacity(0.15)
            : Color.clear
        )
        .padding(6)
    }
}

struct RulerLocked : View{
    
    let rulerType:RulerType

    var body: some View {
        Image("lock")
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
