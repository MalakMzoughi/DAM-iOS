//
//  ProfileComponents.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI

struct FloatingStarsBackground: View {
    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let a = 0.5 + 0.5 * sin(t/1.8)
            let b = 0.5 + 0.5 * sin(t/2.4 + 1.1)
            Canvas { g, size in
                g.fill(Path(ellipseIn: CGRect(x: size.width*0.2, y: size.height*0.1, width: 8, height: 8)),
                       with: .color(.white.opacity(a)))
                g.fill(Path(ellipseIn: CGRect(x: size.width*0.8, y: size.height*0.15, width: 6, height: 6)),
                       with: .color(.white.opacity(b)))
            }
        }
        .ignoresSafeArea()
    }
}

struct AnimatedProfileAvatar: View {
    let name: String
    let photoUrl: URL?
    @State private var up = false

    var body: some View {
        ZStack {
            Circle().fill(
                RadialGradient(colors: [AppColors.rainbowPink, AppColors.rainbowOrange],
                               center: .center, startRadius: 10, endRadius: 80)
            )
            .frame(width: 120, height: 120)
            .scaleEffect(up ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: up)

            if let url = photoUrl {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: { Color.white.opacity(0.3) }
                .clipShape(Circle())
                .frame(width: 120, height: 120)
            } else {
                Text(String(name.prefix(2)).uppercased())
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .onAppear { up = true }
    }
}

struct ProviderBadge: View {
    let provider: String
    var body: some View {
        let color: Color = {
            switch provider.lowercased() {
            case "google": return Color(hex: 0x4285F4)
            case "facebook": return Color(hex: 0x1877F2)
            case "apple": return .black
            default: return .gray
            }
        }()
        return Text(String(provider.prefix(1)).uppercased())
            .font(.system(size: 14, weight: .bold))
            .padding(8)
            .background(color, in: Circle())
            .foregroundStyle(.white)
    }
}

struct StatsCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(icon).font(.system(size: 28))
            Text(title).font(.caption).foregroundStyle(AppColors.textLight)
            Text(value).font(.system(size: 20, weight: .bold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppColors.cardBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}

struct AchievementsSection: View {
    let totalStars: Int
    let maxStars: Int
    var body: some View {
        VStack(spacing: 8) {
            Text("Achievements").font(.title3.bold()).foregroundStyle(.white)
            HStack(spacing: 8) {
                let earned = totalStars / max(1, maxStars/3)
                ForEach(0..<3) { i in
                    Image(systemName: "star.fill")
                        .foregroundStyle(i < earned ? AppColors.rainbowYellow : .gray)
                        .font(.system(size: 28))
                }
            }
        }
    }
}

struct AccountInfoCard: View {
    let profile: UserProfile
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Info")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColors.rainbowBlue)

            infoRow(icon: "person", label: "Name", value: profile.name)
            infoRow(icon: "envelope", label: "Email", value: profile.email ?? "No email (Guest mode)")
            if !profile.provider.isEmpty {
                infoRow(icon: "lock", label: "Login Method", value: profile.provider.capitalized)
            }
            let progress = Int(Double(profile.totalStars) / Double(max(1, profile.maxStars)) * 100)
            infoRow(icon: "star.fill", label: "Progress", value: "\(progress)%")
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading )
        .background(AppColors.cardBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    @ViewBuilder
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(AppColors.rainbowBlue).frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(AppColors.textLight)
                Text(value).font(.body.weight(.medium))
            }
        }
    }
}

// MARK: - My Avatars Section
struct MyAvatarsSection: View {
    let avatars: [Avatar]
    let isLoading: Bool
    let activeAvatar: Avatar?
    var onAvatarTap: ((Avatar) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Avatars")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if avatars.isEmpty {
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
                        ForEach(avatars) { avatar in
                            AvatarProfileCard(
                                avatar: avatar,
                                isActive: activeAvatar?.id == avatar.id,
                                onTap: onAvatarTap != nil ? { onAvatarTap?(avatar) } : nil
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}

// MARK: - Avatar Profile Card
struct AvatarProfileCard: View {
    let avatar: Avatar
    let isActive: Bool
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
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
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(isActive ? Color.yellow : Color.white.opacity(0.5), lineWidth: isActive ? 4 : 2)
                    )
                
                if let avatarUrl = avatar.readyPlayerMeAvatarUrl ?? avatar.readyPlayerMeGlbUrl {
                    let renderUrl = ReadyPlayerMeConfig.getRenderURL(avatarUrl: avatarUrl, scene: "fullbody-portrait-v1")
                    AsyncImage(url: URL(string: renderUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        case .empty:
                            ProgressView()
                                .tint(.white)
                                .frame(width: 100, height: 100)
                        case .failure:
                            fallbackAvatarImage
                        @unknown default:
                            fallbackAvatarImage
                        }
                    }
                } else if let imageUrl = avatar.avatarImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        case .empty:
                            ProgressView()
                                .tint(.white)
                                .frame(width: 100, height: 100)
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
            Text(avatar.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            
            // Active Badge
            if isActive {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Active")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.yellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.2), in: Capsule())
            }
            }
        }
        .frame(width: 140)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var fallbackAvatarImage: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 100, height: 100)
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}
