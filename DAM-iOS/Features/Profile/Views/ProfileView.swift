//
//  ProfileView.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: UserSession
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var settings: AppSettings
    @StateObject private var viewModel = ProfileViewModel()

    @State private var showLogout = false
    @State private var showSettings = false
    @State private var selectedAvatarForEdit: Avatar? = nil
    @State private var showEditAvatar = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppColors.skyBlue,
                                    AppColors.oceanLight,
                                    AppColors.oceanDeep],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            FloatingStarsBackground()
            WaveBackground().opacity(0.7)

            ScrollView {
                VStack(alignment: .center, spacing: 24) {

                    // Back
                    HStack {
                        
                        Button {
                            // Navigate back to home
                            router.current = .home
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 56, height: 56)
                                .background(.white.opacity(0.3), in: Circle())
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        
                        // Settings and Logout buttons (only for logged in)
                        if case .loggedIn = session.state {
                            HStack(spacing: 12) {
                                // Settings Button
                                Button {
                                    showSettings = true
                                } label: {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 18, weight: .bold))
                                        .frame(width: 44, height: 44)
                                        .background(.white.opacity(0.3),
                                                    in: Circle())
                                        .foregroundStyle(AppColors.rainbowBlue)
                                }
                                
                                // Logout Button
                                Button {
                                    showLogout = true
                                } label: {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 18, weight: .bold))
                                        .frame(width: 44, height: 44)
                                        .background(.white.opacity(0.3),
                                                    in: Circle())
                                        .foregroundStyle(AppColors.rainbowRed)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Avatar
                    AnimatedProfileAvatar(
                        name: session.profile.name,
                        photoUrl: session.profile.photoUrl
                    )

                    // Name + provider badge
                    HStack(spacing: 12) {
                        Text((session.profile.name.isEmpty ? "Guest Player" : session.profile.name).uppercased())
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        // Show provider badge only if not guest
                        if session.profile.provider.lowercased() != "guest" {
                            ProviderBadge(provider: session.profile.provider)
                        }
                    }

                    Text(levelTitle(session.profile.level))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))

                    if case .guest = session.state {
                        Text("Guest Mode — Progress not saved")
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.28),
                                        in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }

                    // Stats cards
                    HStack(spacing: 12) {
                        StatsCard(
                            icon: "🏆",
                            title: "Level",
                            value: "\(session.profile.level)",
                            color: AppColors.rainbowYellow
                        )
                        StatsCard(
                            icon: "⭐️",
                            title: "Stars",
                            value: "\(session.profile.totalStars)/\(session.profile.maxStars)",
                            color: AppColors.rainbowOrange
                        )
                    }
                    .padding(.horizontal, 24)

                    // Achievements
                    AchievementsSection(
                        totalStars: session.profile.totalStars,
                        maxStars: session.profile.maxStars
                    )

                    // My Avatars Section (only for logged in users)
                    if case .loggedIn = session.state {
                        MyAvatarsSection(
                            avatars: viewModel.avatars,
                            isLoading: viewModel.isLoading,
                            activeAvatar: session.activeAvatar,
                            onAvatarTap: { avatar in
                                selectedAvatarForEdit = avatar
                                showEditAvatar = true
                            }
                        )
                        .padding(.horizontal, 24)
                    }

                    // Account Info
                    AccountInfoCard(profile: session.profile)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            // Load avatars for logged in users
            if case .loggedIn = session.state {
                viewModel.loadAvatars(userSession: session)
            }
        }
        .onChange(of: session.activeAvatar) { _ in
            // Refresh avatars when active avatar changes
            if case .loggedIn = session.state {
                viewModel.loadAvatars(userSession: session)
            }
        }
        .onChange(of: showEditAvatar) { isShowing in
            // Refresh avatars when edit view is dismissed
            if !isShowing {
                if case .loggedIn = session.state {
                    viewModel.loadAvatars(userSession: session)
                }
            }
        }
        .alert("Logout", isPresented: $showLogout) {
            Button("Cancel", role: .cancel) {}

            Button("Logout", role: .destructive) {
                // New logout behavior with the new architecture:
                // - Clear session
                // - Back to guest
                session.setGuest()
                router.current = .home
            }
        } message: {
            Text("Are you sure you want to logout? Your progress will be saved, but you'll need to login again to access your account.")
        }
        .sheet(isPresented: $showSettings) {
            NavigationView {
                SettingsSheet()
                    .environmentObject(settings)
                    .navigationTitle("Music Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showSettings = false
                            }
                            .font(.system(size: 16, weight: .semibold))
                        }
                    }
            }
        }
        .sheet(isPresented: $showEditAvatar) {
            if let avatar = selectedAvatarForEdit {
                EditAvatarView(avatar: avatar)
                    .environmentObject(session)
            }
        }
    }
    
    // Level title helper function
    private func levelTitle(_ level: Int) -> String {
        switch level {
        case 1: return "Beginner"
        case 2...3: return "Learner"
        case 4...5: return "Player"
        case 6...7: return "Skilled"
        case 8...10: return "Expert"
        default: return "Master"
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .previewDevice("iPad (9th generation)")
            .environmentObject(UserSession())
            .previewLayout(.device)
            .background(Color.white)
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
