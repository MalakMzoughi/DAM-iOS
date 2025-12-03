//
//  AvatarComponents.swift
//  DAM-iOS
//
//  Reusable avatar UI components
//

import SwiftUI

// MARK: - Avatar Image View
struct AvatarImageView: View {
    let avatarUrl: String?
    let size: CGFloat
    
    init(avatarUrl: String?, size: CGFloat = 80) {
        self.avatarUrl = avatarUrl
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            if let urlString = avatarUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure(_):
                        AvatarPlaceholder(size: size)
                    @unknown default:
                        AvatarPlaceholder(size: size)
                    }
                }
            } else {
                AvatarPlaceholder(size: size)
            }
        }
    }
}

struct AvatarPlaceholder: View {
    let size: CGFloat
    
    var body: some View {
        Text("👤")
            .font(.system(size: size / 2))
            .foregroundColor(.white)
    }
}

// MARK: - Avatars Section
struct AvatarsSection: View {
    let avatars: [Avatar]
    let activeAvatar: Avatar?
    let isLoading: Bool
    let onCreateAvatar: () -> Void
    let onSelectAvatar: (Avatar) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Avatars")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onCreateAvatar) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16))
                        Text("Create")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(20)
                }
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                }
                .frame(height: 150)
            } else if avatars.isEmpty {
                VStack(spacing: 12) {
                    Text("👤")
                        .font(.system(size: 48))
                    
                    Text("No avatars yet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Create your first avatar!")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(avatars) { avatar in
                            AvatarCard(
                                avatar: avatar,
                                isActive: avatar.id == activeAvatar?.id,
                                onTap: { onSelectAvatar(avatar) }
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Avatar Card
struct AvatarCard: View {
    let avatar: Avatar
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    AvatarImageView(avatarUrl: avatar.avatarImageUrl, size: 80)
                    
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                            .background(Circle().fill(Color.white))
                    }
                }
                
                VStack(spacing: 4) {
                    Text(avatar.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("Lvl \(avatar.level)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 120)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isActive ? 0.3 : 0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isActive ? Color.green : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - Avatar Stats View
struct AvatarStatsView: View {
    let avatar: Avatar
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatItem(icon: "star.fill", label: "Level", value: "\(avatar.level)", color: .yellow)
                StatItem(icon: "bolt.fill", label: "Energy", value: "\(avatar.energy)", color: .orange)
                StatItem(icon: "chart.bar.fill", label: "XP", value: "\(avatar.experience)", color: .blue)
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}
