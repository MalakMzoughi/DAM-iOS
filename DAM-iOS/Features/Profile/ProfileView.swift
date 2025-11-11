//
//  ProfileView.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 10/11/2025.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: UserSession

    @State private var showLogout = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppColors.rainbowIndigo, AppColors.rainbowViolet, AppColors.rainbowPink],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            FloatingStarsBackground()

            ScrollView {
                VStack(alignment: .center, spacing: 24) {

                    // Back
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 56, height: 56)
                                .background(.white.opacity(0.3), in: Circle())
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Avatar
                    AnimatedProfileAvatar(name: session.profile.name,
                                          photoUrl: session.profile.photoUrl)

                    // Name + provider badge
                    HStack(spacing: 12) {
                        Text((session.profile.name.isEmpty ? "Guest Player" : session.profile.name).uppercased())
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        if let provider = session.profile.provider {
                            ProviderBadge(provider: provider)
                        }
                    }

                    Text(levelTitle(session.profile.level))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))

                    if case .guest = session.state {
                        Text("Guest Mode — Progress not saved")
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.white.opacity(0.28), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }

                    // Stats cards
                    HStack(spacing: 12) {
                        StatsCard(icon: "🏆", title: "Level",
                                  value: "\(session.profile.level)",
                                  color: AppColors.rainbowYellow)
                        StatsCard(icon: "⭐️", title: "Stars",
                                  value: "\(session.profile.totalStars)/\(session.profile.maxStars)",
                                  color: AppColors.rainbowOrange)
                    }
                    .padding(.horizontal, 24)

                    // Achievements
                    AchievementsSection(totalStars: session.profile.totalStars,
                                        maxStars: session.profile.maxStars)

                    // Account Info
                    AccountInfoCard(profile: session.profile)
                        .padding(.horizontal, 24)

                    // Logout (only for logged in)
                    if case .loggedIn = session.state {
                        Button {
                            showLogout = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Logout").bold()
                            }
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.rainbowRed, in: RoundedRectangle(cornerRadius: 30))
                            .foregroundStyle(.white)
                            .shadow(radius: 8, y: 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                    }
                }
                .padding(.top, 8)
            }
        }
        .alert("See you soon!", isPresented: $showLogout) {
            Button("Cancel", role: .cancel) {}
            Button("Yes, Logout", role: .destructive) {
                Task {
                    session.logoutFromGoogle()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

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

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(UserSession())
            .previewLayout(.sizeThatFits)
            .background(Color.white)
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
