//
//  HomeDrawerView.swift
//  DAM-iOS
//
//  Side drawer menu with avatar-themed styling
//

import SwiftUI

struct HomeDrawerView: View {
    let userName: String
    let avatarImageUrl: String?
    let avatarName: String?
    let fallbackEmoji: String
    let isLoggedIn: Bool
    let accentColor: Color
    
    let onProfileClick: () -> Void
    let onRecognizeClick: () -> Void
    let onAddAvatarClick: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Scrim overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }
            
            // Drawer content
            VStack(alignment: .leading, spacing: 0) {
                // Profile header
                VStack(alignment: .leading, spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 112, height: 112)
                            .overlay(
                                Circle()
                                    .stroke(accentColor.opacity(0.4), lineWidth: 3)
                            )
                        
                        if let avatarImageUrl = avatarImageUrl, let url = URL(string: avatarImageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Text(fallbackEmoji)
                                    .font(.system(size: 42))
                            }
                            .frame(width: 112, height: 112)
                            .clipShape(Circle())
                        } else {
                            Text(fallbackEmoji)
                                .font(.system(size: 42))
                        }
                    }
                    .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userName.isEmpty ? "Hey there!" : "Hi, \(userName)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(subtitleText)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 24)
                
                Divider()
                    .background(Color.white.opacity(0.18))
                    .padding(.horizontal, 20)
                
                // Menu items
                VStack(spacing: 24) {
                    DrawerActionButton(
                        icon: "person.fill",
                        label: "Profile",
                        description: "View progress & settings",
                        accentColor: Color(red: 0.4, green: 0.7, blue: 1.0), // RainbowBlue
                        action: onProfileClick
                    )
                    
                    DrawerActionButton(
                        icon: "waveform",
                        label: "Recognize",
                        description: "Identify what you're playing",
                        accentColor: Color(red: 0.5, green: 0.4, blue: 1.0), // RainbowIndigo
                        action: onRecognizeClick
                    )
                    
                    DrawerActionButton(
                        icon: "plus.circle.fill",
                        label: isLoggedIn ? "Add Avatar" : "Sign In & Add Avatar",
                        description: isLoggedIn ? "Create a new hero" : "Tap to unlock custom avatars",
                        accentColor: Color(red: 1.0, green: 0.4, blue: 0.8), // RainbowPink
                        action: onAddAvatarClick
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                
                Spacer()
                
                // Support info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Need help?")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("support@pianokids.app")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .frame(width: 320)
            .background(drawerBackgroundGradient)
            .ignoresSafeArea()
        }
    }
    
    private var subtitleText: String {
        if !isLoggedIn {
            return "Sign in to save your music journey"
        } else if let avatarName = avatarName {
            return "Avatar: \(avatarName)"
        } else {
            return "Create an avatar to join the band"
        }
    }
    
    private var drawerBackgroundGradient: LinearGradient {
        // Mix accent color with black for rich background
        let darkAccent = Color(
            red: accentColor.components.red * 0.45,
            green: accentColor.components.green * 0.45,
            blue: accentColor.components.blue * 0.45
        )
        
        return LinearGradient(
            colors: [darkAccent, darkAccent.opacity(0.9)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct DrawerActionButton: View {
    let icon: String
    let label: String
    let description: String
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.08))
            .cornerRadius(24)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Helper extension to get color components
extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        #if canImport(UIKit)
        guard let components = UIColor(self).cgColor.components else {
            return (0, 0, 0, 0)
        }
        return (
            red: Double(components[0]),
            green: Double(components[1]),
            blue: Double(components[2]),
            opacity: Double(components[3])
        )
        #else
        return (0, 0, 0, 1)
        #endif
    }
}
