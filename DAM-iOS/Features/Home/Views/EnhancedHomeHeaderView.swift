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
    let onBackTap: () -> Void
    let onProfileTap: () -> Void
    let onAddAvatarTap: () -> Void
    let onMusicRecognitionTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Back Button
            Button(action: onBackTap) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "4A90E2"))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "4A90E2").opacity(0.2))
                    .clipShape(Circle())
            }
            
            Spacer().frame(width: 8)
            
            // Profile Section
            HStack(spacing: 8) {
                Button(action: onProfileTap) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.pink],
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
                            .foregroundColor(Color(hex: "667EEA"))
                    } else {
                        Text("No avatar")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                // Music Recognition Button
                Button(action: onMusicRecognitionTap) {
                    HStack(spacing: 4) {
                        Text("🎵")
                            .font(.system(size: 16))
                        Text("Recognize")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "667EEA"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "667EEA").opacity(0.2))
                    .cornerRadius(18)
                }
                .frame(height: 36)
                
                // Add Avatar Button (only for logged in)
                if isLoggedIn {
                    Button(action: onAddAvatarTap) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Avatar")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "4A90E2"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: "4A90E2").opacity(0.2))
                        .cornerRadius(18)
                    }
                    .frame(height: 36)
                }
                
                // Stars Display
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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
    }
}
