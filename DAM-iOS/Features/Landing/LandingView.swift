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
    @EnvironmentObject var session: UserSession
    @State private var showSettings = false
    @State private var showLogin = false
    @State private var floatUp = false
    static let islandwidthFraction: CGFloat = 2.5

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [AppColors.skyBlue, AppColors.oceanDeep],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                WaveBackground().opacity(0.25)

                HStack(spacing: 24) {
                VStack {
                        Spacer()
                    if let _ = UIImage(named: "island") {
                    AppImages.island
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geo.size.width * LandingView.islandwidthFraction)
                        .offset(y: floatUp ? -8 : 8)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: floatUp)
                        .onAppear { floatUp = true }
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

                VStack(alignment: .leading, spacing: 16) {
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

                CenterDialog(isPresented: $showSettings) {
                    SettingsSheet().environmentObject(settings)
                }
                CenterDialog(isPresented: $showLogin) {
                    LoginSheet()
                        .environmentObject(session)
                        .environmentObject(router)
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
