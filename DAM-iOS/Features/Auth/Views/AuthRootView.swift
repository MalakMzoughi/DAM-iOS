//
//  AuthRootView.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI
import GoogleSignInSwift

struct AuthRootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var session: UserSession

    @StateObject private var authViewModel = AuthViewModel.make()

    @State private var showSettings = false
    @State private var showLogin = false
    @State private var floatUp = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // BACKGROUND GRADIENT
                LinearGradient(colors: [AppColors.skyBlue, AppColors.oceanDeep],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                // WAVES
                WaveBackground().opacity(0.25)

                // 🏝 ISLAND AS BACKGROUND LAYER (NOT IN HSTACK)
                if UIImage(named: "island") != nil {
                    AppImages.island
                        .resizable()
                        .scaledToFit()
                        // Big island, behaves like a background illustration
                        .frame(width: geo.size.width * 0.90)
                        // Place it on the left side of the screen
                        .position(x: geo.size.width * 0.35,
                                  y: geo.size.height * 0.50)
                        .offset(y: floatUp ? -10 : 10)
                        .animation(
                            .easeInOut(duration: 3)
                                .repeatForever(autoreverses: true),
                            value: floatUp
                        )
                        .onAppear { floatUp = true }
                        .shadow(radius: 12, y: 8)
                }

                // FOREGROUND CONTENT (only right column, centered nicely)
                HStack {
                    
                    // Reserve space on the left for the island
                    Spacer().frame(width: geo.size.width * 0.60)

                    // RIGHT: TITLE + MASCOT + BUTTONS
                    VStack(alignment: .leading, spacing: 16) {
                        // Settings button
                        HStack {
                            Spacer()
                            Button { showSettings.toggle() } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .padding(12)
                                    .background(AppColors.cardBackground.opacity(0.2), in: Circle())
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                                    )
                            }
                        }

                        // Mascot + title
                        HStack(alignment: .center, spacing: 16) {
                            AppImages.mascot
                                .resizable()
                                .scaledToFit()
                                .frame(height: geo.size.height * 0.45)
                                .shadow(radius: 10)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tune Island")
                                    .font(.system(size: 56,
                                                  weight: .bold,
                                                  design: .rounded))
                                    .foregroundStyle(AppColors.cardBackground)
                                    .shadow(color: .black.opacity(0.35),
                                            radius: 6,
                                            y: 3)

                                Text("Learn Piano with Us!")
                                    .font(.system(size: 22,
                                                  weight: .semibold,
                                                  design: .rounded))
                                    .foregroundStyle(AppColors.rainbowBlue)
                            }
                        }

                        Spacer().frame(height: 8)

                        // BUTTONS CENTERED UNDER THE TITLE
                        HStack {
                            Spacer()

                            VStack(spacing: 12) {
                                Button {
                                    settings.hasPlayedBefore = true
                                    router.current = .home
                                } label: {
                                    Text(settings.hasPlayedBefore ? "Continue Playing"
                                                                  : "Start as Guest")
                                        .frame(maxWidth: 320)
                                }
                                .buttonStyle(GradientButtonStyle(gradient: .guestYellow))

                                Button { showLogin.toggle() } label: {
                                    Text("Login")
                                        .frame(maxWidth: 320)
                                }
                                .buttonStyle(GradientButtonStyle(gradient: .loginPurple))
                            }

                            Spacer()
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 28)

                    Spacer().frame(width: geo.size.width * 0.05)
                }

                // Settings sheet
                CenterDialog(isPresented: $showSettings) {
                    SettingsSheet().environmentObject(settings)
                }

                // Login sheet
                CenterDialog(isPresented: $showLogin) {
                    LoginSheet()
                        .environmentObject(session)
                        .environmentObject(router)
                        .environmentObject(authViewModel)
                }
            }
            // When auth succeeds, update session, close sheet, go to home
            .onChange(of: authViewModel.isAuthenticated) { isAuth in
                if isAuth,
                   let token = authViewModel.lastAuthToken,
                   let profile = authViewModel.userProfile {
                    session.setLoggedIn(authToken: token, profile: profile)
                    showLogin = false
                    router.current = .home
                }
            }
        }
    }
}

struct AuthRootView_Previews: PreviewProvider {
    static var previews: some View {
        AuthRootView()
            .previewDevice("iPad (9th generation)")
            .environmentObject(AppSettings())
            .environmentObject(AppRouter())
            .environmentObject(UserSession())
            .previewLayout(.device)
            .background(Color.white)
            .previewInterfaceOrientation(.landscapeRight)
    }
}



