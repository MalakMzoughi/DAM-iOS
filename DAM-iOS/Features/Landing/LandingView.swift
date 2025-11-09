//
//  LandingView.swift
//  DAM-iOS
//
//  Created by iMac on 9/11/2025.
//

import SwiftUI

struct LandingView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject var router: AppRouter
    @State private var showSettings = false
    @State private var showLogin = false
    static let islandwidthFraction: CGFloat = 0.60

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Sky → ocean background like Android
                LinearGradient(colors: [AppColors.skyBlue, AppColors.oceanDeep],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                // Subtle wave decoration at the bottom
                WaveBackground().opacity(0.25)

                // Two-column layout to match your screenshot
                HStack(spacing: 24) {
                    // LEFT: Floating island art
                    VStack {
                        Spacer()
                        if let _ = UIImage(named: "island") {
                            AppImages.island
                                .resizable()
                                .scaledToFit()
                                    .frame(maxWidth: geo.size.width * LandingView.islandwidthFraction)
                                .shadow(radius: 12, y: 8)
                        } else {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(AppColors.seaFoam.opacity(0.2))
                                .frame(width: geo.size.width * 0.42,
                                       height: geo.size.height * 0.55)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 24)

                    // RIGHT: Mascot + title/subtitle + buttons
                    VStack(alignment: .leading, spacing: 16) {
                        // Top-right gear
                        HStack {
                            Spacer()
                            Button { showSettings.toggle() } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .padding(12)
                                    .background(AppColors.cardBackground.opacity(0.2), in: Circle())
                                    .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                            }
                        }

                        HStack(alignment: .center, spacing: 16) {
                            AppImages.mascot
                                .resizable()
                                .scaledToFit()
                                .frame(height: geo.size.height * 0.45)
                                .shadow(radius: 10)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Piano Kids") // swap to final name later
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppColors.cardBackground)
                                    .shadow(color: .black.opacity(0.35), radius: 6, y: 3)

                                Text("Learn Piano with Us!")
                                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppColors.rainbowBlue)
                            }
                        }

                        Spacer().frame(height: 8)

                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                settings.hasPlayedBefore = true
                                router.current = .home
                            } label: {
                                Text(settings.hasPlayedBefore ? "Continue Playing" : "Start as Guest")
                                    .frame(maxWidth: 320)
                            }
                            .buttonStyle(GradientButtonStyle(gradient: .guestYellow))

                            Button { showLogin.toggle() } label: {
                                Text("Login").frame(maxWidth: 320)
                            }
                            .buttonStyle(GradientButtonStyle(gradient: .loginPurple))
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 28)
                }

                // COMPACT dialogs (no full-screen sheets)
                CenterDialog(isPresented: $showSettings) {
                    SettingsSheet().environmentObject(settings)
                }
                CenterDialog(isPresented: $showLogin) {
                    LoginSheet(onApple: {}, onGoogle: {}, onFacebook: {})
                }
            }
        }
    }
}


struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
            .environmentObject(AppSettings())
            .previewLayout(.sizeThatFits)
            .background(Color.white)
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
