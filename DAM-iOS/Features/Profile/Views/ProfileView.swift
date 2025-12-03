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
    @State private var selectedAIAvatar: Avatar? = nil
    @State private var showAIAvatarDetail = false
    @State private var showAddAvatar = false
    @State private var showMusicRecognition = false
    @State private var avatarPendingDeletion: Avatar? = nil
    @State private var showDeleteConfirmation = false
    @State private var showEditName = false


    var body: some View {
        let profile = session.profile
        let avatarURL = session.activeAvatar?.avatarImageUrl.flatMap { URL(string: $0) } ?? profile.photoUrl
        let initials = profile.name.isEmpty ? "GP" : String(profile.name.prefix(2)).uppercased()

        return ZStack {
            LinearGradient(colors: [AppColors.skyBlue,
                                    AppColors.oceanLight,
                                    AppColors.oceanDeep],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            AnimatedKidsBackground()
            WaveBackground().opacity(0.35)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    FunTopBar(
                        onNavigateBack: { router.current = .home },
                        onSettings: { showSettings = true },
                        onLogout: session.isLoggedIn ? { showLogout = true } : nil,
                        onMusic: session.isLoggedIn ? { showMusicRecognition = true } : nil
                    )
                    .padding(.top, 24)

                    PlayfulProfileAvatar(
                        avatarURL: avatarURL,
                        initials: initials
                    ) {
                        if let avatar = session.activeAvatar {
                            handleAvatarTap(avatar)
                        }
                    }
                    .padding(.top, 8)

                    KidsNameSection(
                        userName: profile.name.isEmpty ? "Guest Player" : profile.name,
                        provider: profile.provider,
                        onEdit: session.isLoggedIn ? { showEditName = true } : nil
                    )

                    KidsLevelBadge(userLevel: profile.level)

                    if case .guest = session.state {
                        GuestModeBanner()
                    }

                    KidsStatsCards(
                        userLevel: profile.level,
                        totalStars: profile.totalStars,
                        maxStars: profile.maxStars
                    )

                    KidsAchievementsSection(
                        totalStars: profile.totalStars,
                        userLevel: profile.level,
                        maxStars: profile.maxStars
                    )

                    if case .loggedIn = session.state {
                        KidsAvatarsSection(
                            avatars: viewModel.avatars,
                            isLoading: viewModel.isLoading,
                            activeAvatar: session.activeAvatar,
                            onAvatarTap: { avatar in
                                handleAvatarTap(avatar)
                            },
                            onActivateAvatar: { avatar in
                                activateAvatar(avatar)
                            },
                            onDeleteAvatar: { avatar in
                                avatarPendingDeletion = avatar
                                showDeleteConfirmation = true
                            },
                            onCreateAvatarTap: {
                                showAddAvatar = true
                            }
                        )
                    }

                    KidsAccountInfoCard(profile: profile)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
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
        .sheet(isPresented: $showEditName) {
            KidsEditNameSheet(currentName: session.profile.name.isEmpty ? "Guest Player" : session.profile.name) { newName in
                session.updateProfileName(newName)
            }
        }
        .sheet(isPresented: $showEditAvatar) {
            if let avatar = selectedAvatarForEdit {
                EditAvatarView(avatar: avatar)
                    .environmentObject(session)
            }
        }
        .sheet(isPresented: $showAddAvatar) {
            AvatarNameInputView()
                .environmentObject(session)
        }
        .sheet(isPresented: $showAIAvatarDetail) {
            if let avatar = selectedAIAvatar {
                AIAvatarDetailSheet(
                    avatar: avatar,
                    isActive: session.activeAvatar?.id == avatar.id,
                    onSetActive: {
                        showAIAvatarDetail = false
                        activateAvatar(avatar)
                    },
                    onDelete: {
                        showAIAvatarDetail = false
                        avatarPendingDeletion = avatar
                        showDeleteConfirmation = true
                    },
                    onClose: {
                        showAIAvatarDetail = false
                    }
                )
            }
        }
        .sheet(isPresented: $showMusicRecognition) {
            MusicRecognitionView()
        }
        .onChange(of: showAddAvatar) { isShowing in
            // Refresh avatars when the create-avatar sheet is dismissed
            if !isShowing {
                if case .loggedIn = session.state {
                    viewModel.loadAvatars(userSession: session)
                }
            }
        }
        .alert("Delete Avatar?", isPresented: $showDeleteConfirmation, presenting: avatarPendingDeletion) { avatar in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAvatar(avatar)
            }
        } message: { avatar in
            Text("This will permanently remove \(avatar.name).")
        }
    }
}

// MARK: - Private Helpers
extension ProfileView {
    private func handleAvatarTap(_ avatar: Avatar) {
        if avatar.readyPlayerMeAvatarUrl != nil || avatar.readyPlayerMeGlbUrl != nil {
            selectedAvatarForEdit = avatar
            showEditAvatar = true
        } else {
            selectedAIAvatar = avatar
            showAIAvatarDetail = true
        }
    }
    
    private func activateAvatar(_ avatar: Avatar) {
        Task {
            await viewModel.setActiveAvatar(avatar, userSession: session)
        }
    }
    
    private func deleteAvatar(_ avatar: Avatar) {
        Task {
            await viewModel.deleteAvatar(avatar, userSession: session)
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
