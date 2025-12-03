//
//  AvatarDetailsView.swift
//  DAM-iOS
//
//  View to display avatar details when clicking on profile photo
//

import SwiftUI

struct AvatarDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: UserSession
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [AppColors.skyBlue,
                                        AppColors.oceanLight,
                                        AppColors.oceanDeep],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            Text("Avatar Details")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Active Avatar Display
                        if let activeAvatar = session.activeAvatar {
                            VStack(spacing: 20) {
                                // Large Avatar Image
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    AppColors.rainbowPink.opacity(0.4),
                                                    AppColors.rainbowOrange.opacity(0.4)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 200, height: 200)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.yellow, lineWidth: 4)
                                        )
                                    
                                    if let imageUrl = activeAvatar.avatarImageUrl, let url = URL(string: imageUrl) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 180, height: 180)
                                                    .clipShape(Circle())
                                            case .empty:
                                                ProgressView()
                                                    .tint(.white)
                                                    .frame(width: 180, height: 180)
                                            case .failure:
                                                fallbackAvatarImage
                                            @unknown default:
                                                fallbackAvatarImage
                                            }
                                        }
                                    } else {
                                        fallbackAvatarImage
                                    }
                                }
                                
                                // Avatar Name
                                Text(activeAvatar.name)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(.white)
                                
                                // Active Badge
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Active Avatar")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.yellow.opacity(0.2), in: Capsule())
                                
                                // Avatar Stats
                                HStack(spacing: 30) {
                                    VStack(spacing: 8) {
                                        Text("\(activeAvatar.level)")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundStyle(AppColors.rainbowYellow)
                                        Text("Level")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Text("\(activeAvatar.experience)")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundStyle(AppColors.rainbowOrange)
                                        Text("Experience")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Text("\(activeAvatar.energy)")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundStyle(AppColors.rainbowGreen)
                                        Text("Energy")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }
                                .padding(.vertical, 20)
                                .padding(.horizontal, 30)
                                .background(AppColors.cardBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: 20))
                            }
                            .padding(.horizontal, 24)
                        } else {
                            // No active avatar
                            VStack(spacing: 20) {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.system(size: 80))
                                    .foregroundStyle(.white.opacity(0.6))
                                
                                Text("No Active Avatar")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                                
                                Text("Create an avatar to get started!")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .padding(.vertical, 60)
                        }
                        
                        // All Avatars Section
                        if case .loggedIn = session.state {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("All My Avatars")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 24)
                                
                                if viewModel.isLoading {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .tint(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 40)
                                } else if viewModel.avatars.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .font(.system(size: 48))
                                            .foregroundStyle(.white.opacity(0.6))
                                        Text("No avatars created yet")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(viewModel.avatars) { avatar in
                                                AvatarDetailsCard(
                                                    avatar: avatar,
                                                    isActive: session.activeAvatar?.id == avatar.id
                                                )
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                }
                            }
                            .padding(.top, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            viewModel.loadAvatars(userSession: session)
        }
    }
    
    private var fallbackAvatarImage: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 180, height: 180)
            Image(systemName: "person.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

// MARK: - Avatar Details Card
struct AvatarDetailsCard: View {
    let avatar: Avatar
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Avatar Image
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.rainbowPink.opacity(0.3),
                                AppColors.rainbowOrange.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(isActive ? Color.yellow : Color.white.opacity(0.5), lineWidth: isActive ? 3 : 2)
                    )
                
                if let imageUrl = avatar.avatarImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                        case .empty:
                            ProgressView()
                                .tint(.white)
                                .frame(width: 90, height: 90)
                        case .failure:
                            fallbackImage
                        @unknown default:
                            fallbackImage
                        }
                    }
                } else {
                    fallbackImage
                }
            }
            
            // Avatar Name
            Text(avatar.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            
            // Active Badge
            if isActive {
                Text("Active")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2), in: Capsule())
            }
        }
        .frame(width: 120)
        .padding()
        .background(AppColors.cardBackground.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var fallbackImage: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 90, height: 90)
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

