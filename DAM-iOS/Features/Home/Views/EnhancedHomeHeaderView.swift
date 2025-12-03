//
//  EnhancedHomeHeaderView.swift
//  DAM-iOS
//
//  Enhanced header with Avatar AI and Music Recognition buttons
//

import SwiftUI

struct EnhancedHomeHeaderView: View {
    let profile: UserProfile
    let isLoggedIn: Bool
    let totalStars: Int
    let activeAvatar: Avatar?
    let accentColor: Color
    let onAvatarTap: () -> Void
    // Removed action buttons; avatar tap opens drawer
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Section - Clickable to open drawer
            HStack(spacing: 8) {
                Button(action: onAvatarTap) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(0.6),
                                        accentColor,
                                        accentColor.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 45, height: 45)
                        
                        // Show avatar image, then Google photo, then default
                        if let avatarUrl = activeAvatar?.avatarImageUrl,
                           let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                        } else if let photoUrl = profile.photoUrl {
                            AsyncImage(url: photoUrl) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    Text("🎹")
                                        .font(.system(size: 24))
                                }
                            }
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                        } else {
                            Text("🎹")
                                .font(.system(size: 24))
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !isLoggedIn {
                        Text("Guest Mode")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    } else if let avatarName = activeAvatar?.name {
                        Text(avatarName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(accentColor)
                    } else {
                        Text("No avatar")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Right side: stars only (no buttons)
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                    Text("\(totalStars)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.9))
                .cornerRadius(18)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    accentColor.opacity(0.4),
                    accentColor.opacity(0.5),
                    accentColor.opacity(0.45)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
