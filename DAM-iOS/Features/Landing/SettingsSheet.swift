//
//  SettingsSheet.swift
//  DAM-iOS
//
//  Created by iMac on 9/11/2025.
//

import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        VStack(spacing: 22) {
            Text("Settings")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textDark)
            
            Toggle(isOn: $settings.musicOn) {
                Text("Music")
            }
            .toggleStyle(SwitchToggleStyle(tint: AppColors.rainbowBlue))
            
            if settings.musicOn {
                HStack {
                    Text("Volume")
                    Slider(value: $settings.musicVolume, in: 0...1, step: 0.01)
                }
            }
            
            Toggle(isOn: $settings.vibrationOn) {
                Text("Game Sounds")
            }
            .toggleStyle(SwitchToggleStyle(tint: AppColors.rainbowBlue))
            
            Toggle(isOn: $settings.vibrationOn) {
                Text("Vibration")
            }
            .toggleStyle(SwitchToggleStyle(tint: AppColors.rainbowBlue))
            
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: 540)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
        )
        .padding(24)
        .frame(maxWidth: 520)
        .frame(maxHeight: 350)
    }
}

struct SettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSheet()
            .environmentObject(AppSettings())
            .previewLayout(.sizeThatFits)
            .background(AppColors.gameBackground)
            .previewInterfaceOrientation(.landscapeLeft)
    }
}

