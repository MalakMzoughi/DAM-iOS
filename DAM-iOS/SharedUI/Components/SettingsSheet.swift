//
//  SettingsSheet.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [AppColors.skyBlue,
                                    AppColors.oceanLight,
                                    AppColors.oceanDeep],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Music Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Music Settings")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        // Music Toggle
                        HStack {
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundStyle(AppColors.rainbowBlue)
                                .frame(width: 30)
                            
                            Text("Background Music")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Toggle("", isOn: $settings.musicOn)
                                .toggleStyle(SwitchToggleStyle(tint: AppColors.rainbowBlue))
                        }
                        .padding()
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        
                        // Volume Slider (only if music is on)
                        if settings.musicOn {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "speaker.wave.2")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .frame(width: 30)
                                    
                                    Text("Volume")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.9))
                                    
                                    Spacer()
                                    
                                    Text("\(Int(settings.musicVolume * 100))%")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                
                                Slider(value: $settings.musicVolume, in: 0...1, step: 0.01)
                                    .tint(AppColors.rainbowBlue)
                            }
                            .padding()
                            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Game Sounds Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sound Effects")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        // Game Sounds Toggle
                        HStack {
                            Image(systemName: "speaker.wave.3")
                                .font(.system(size: 20))
                                .foregroundStyle(AppColors.rainbowOrange)
                                .frame(width: 30)
                            
                            Text("Game Sounds")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Toggle("", isOn: $settings.gameSoundsOn)
                                .toggleStyle(SwitchToggleStyle(tint: AppColors.rainbowOrange))
                        }
                        .padding()
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        
                        // Vibration Toggle
                        HStack {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .font(.system(size: 20))
                                .foregroundStyle(AppColors.rainbowGreen)
                                .frame(width: 30)
                            
                            Text("Vibration")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Toggle("", isOn: $settings.vibrationOn)
                                .toggleStyle(SwitchToggleStyle(tint: AppColors.rainbowGreen))
                        }
                        .padding()
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }
}
