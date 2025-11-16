//
//  PianoView.swift
//  DAM-iOS
//
//  Piano Page with Avatar Integration
//  Created by Apple Esprit on 13/11/2025
//

import SwiftUI

struct PianoView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var userSession: UserSession
    @StateObject private var viewModel: PianoViewModel
    
    // States for score and stars (to implement later)
    @State private var stars: Int = 0
    @State private var maxStars: Int = 3
    @State private var score: Int = 0
    
    let level: Level
    
    // Initialization with level
    init(level: Level) {
        self.level = level
        _viewModel = StateObject(wrappedValue: PianoViewModel(level: level.index))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image (bg_level1)
                backgroundLayer
                
                VStack(spacing: 0) {
                    // HEADER: Top bar with stars, title, and score
                    enhancedHeaderBar
                        .padding(.top, 20)
                    
                    Spacer().frame(height: 40)
                    
                    // AVATAR: User's avatar with spotlight
                    avatarWithSpotlight
                    
                    Spacer()
                    
                    // BEGINNER NOTE INDICATORS: Show notes in the middle for beginners
                    beginnerNoteIndicators
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // PIANO KEYBOARD: Interactive keyboard (pushed to bottom)
                    PianoKeyboardView(keys: viewModel.keys) { key in
                        viewModel.playKey(key)
                    }
                    .padding(.bottom, 30)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .onAppear {
            // Automatically load and set the first assistant avatar
            loadFirstAssistantAvatar()
        }
    }
    
    // MARK: - Load First Assistant Avatar
    private func loadFirstAssistantAvatar() {
        // If user is logged in, try to fetch their avatars and use the first one
        if case .loggedIn = userSession.state,
           let authToken = userSession.authToken,
           let providerId = userSession.providerId {
            
            Task {
                do {
                    let avatars = try await AvatarAPI.getUserAvatars(authToken: authToken, providerId: providerId)
                    await MainActor.run {
                        // Use the first avatar if available
                        if let firstAvatar = avatars.first {
                            userSession.setActiveAvatar(firstAvatar)
                            print("✅ Auto-selected first assistant avatar: \(firstAvatar.name)")
                        } else {
                            // No avatars, use default level character
                            userSession.setActiveAvatar(nil)
                            print("ℹ️ No avatars found, using default level character")
                        }
                    }
                } catch {
                    await MainActor.run {
                        print("⚠️ Failed to load avatars: \(error.localizedDescription)")
                        // Use default level character
                        userSession.setActiveAvatar(nil)
                    }
                }
            }
        } else {
            // Guest user - use default level character
            userSession.setActiveAvatar(nil)
            print("ℹ️ Guest user, using default level character")
        }
    }
    
    // MARK: - Beginner Note Indicators
    private var beginnerNoteIndicators: some View {
        VStack(spacing: 15) {
            // Title
            Text("Follow These Notes")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 2)
            
            // Note sequence display
            HStack(spacing: 20) {
                ForEach(viewModel.beginnerSequence, id: \.self) { noteName in
                    NoteIndicatorView(noteName: noteName, keys: viewModel.keys)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            )
        }
    }
    
    // MARK: - Background Layer (bg_level1 Image)
    private var backgroundLayer: some View {
        GeometryReader { geo in
            Image("bg_level1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .overlay(
                    // Slight dark overlay for better readability
                    Color.black.opacity(0.2)
                )
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Enhanced Header Bar (Centered Title)
    private var enhancedHeaderBar: some View {
        ZStack {
            // CENTER: Level Title with Ribbon
            levelRibbon
            
            HStack {
                // LEFT: Back Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 5, x: 0, y: 3)
                }
                .padding(.leading, 30)
                
                Spacer()
                
                // RIGHT: Stars and Score
                rightInfoPanel
                    .padding(.trailing, 30)
            }
        }
    }
    
    // MARK: - Level Ribbon (Center)
    private var levelRibbon: some View {
        ZStack {
            // Ribbon background
            HStack(spacing: 0) {
                // Left torn edge
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(90))
                    .foregroundColor(Color(red: 0.8, green: 0.15, blue: 0.2))
                    .frame(width: 10)
                    .offset(x: 5)
                
                // Main ribbon
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.25, blue: 0.3),
                                Color(red: 0.85, green: 0.15, blue: 0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 55)
                
                // Right torn edge
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(-90))
                    .foregroundColor(Color(red: 0.8, green: 0.15, blue: 0.2))
                    .frame(width: 10)
                    .offset(x: -5)
            }
            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
            
            // Text content
            HStack(spacing: 8) {
                Text("Level \(level.index):")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                
                Text(level.name)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: 280)
    }
    
    // MARK: - Right Info Panel (Stars + Score + Badge)
    private var rightInfoPanel: some View {
        HStack(spacing: 20) {
            // Stars display
            HStack(spacing: 5) {
                ForEach(0..<maxStars, id: \.self) { index in
                    Image(systemName: index < stars ? "star.fill" : "star")
                        .font(.system(size: 28))
                        .foregroundColor(index < stars ? .yellow : .white.opacity(0.4))
                        .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                }
                
                Text("\(stars)/\(maxStars)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, 5)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
            )
            
            // Avatar Badge with Score
            HStack(spacing: 10) {
                // Avatar icon placeholder
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.95))
                        .frame(width: 45, height: 45)
                    
                    // Avatar icon (simple version)
                    Image(systemName: "person.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                }
                .shadow(color: .yellow.opacity(0.5), radius: 8, x: 0, y: 0)
                .shadow(color: .black.opacity(0.4), radius: 5, x: 0, y: 3)
                
                // Score
                Text("\(score)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
            )
        }
    }
    
    // MARK: - Avatar with Spotlight
    private var avatarWithSpotlight: some View {
        ZStack {
            // Spotlight effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(0.5),
                            Color.yellow.opacity(0.25),
                            Color.yellow.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 10)
            
            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(0.6),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
            
            // Avatar Image
            if let avatar = userSession.activeAvatar {
                // Use Ready Player Me render URL if available
                if let avatarUrl = avatar.readyPlayerMeAvatarUrl ?? avatar.readyPlayerMeGlbUrl {
                    let renderUrl = ReadyPlayerMeConfig.getRenderURL(avatarUrl: avatarUrl, scene: "fullbody-portrait-v1")
                    AsyncImage(url: URL(string: renderUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 240, height: 240)
                                .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 8)
                        case .empty:
                            ProgressView()
                                .frame(width: 240, height: 240)
                        case .failure:
                            fallbackAvatar
                        @unknown default:
                            fallbackAvatar
                        }
                    }
                } else if let imageUrl = avatar.avatarImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 240, height: 240)
                                .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 8)
                        case .empty:
                            ProgressView()
                                .frame(width: 240, height: 240)
                        case .failure:
                            fallbackAvatar
                        @unknown default:
                            fallbackAvatar
                        }
                    }
                } else {
                    fallbackAvatar
                }
            } else {
                // Fallback to level character image if no avatar
                Image("level_\(level.index)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 8)
            }
        }
    }
    
    // MARK: - Fallback Avatar
    private var fallbackAvatar: some View {
        Image("level_\(level.index)")
            .resizable()
            .scaledToFit()
            .frame(width: 240, height: 240)
            .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Note Indicator View
struct NoteIndicatorView: View {
    let noteName: String
    let keys: [PianoKey]
    
    var keyColor: Color {
        keys.first(where: { $0.note == noteName })?.color ?? Color.gray
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Note circle with color
            ZStack {
                Circle()
                    .fill(keyColor)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: keyColor.opacity(0.6), radius: 8, x: 0, y: 4)
                
                Text(noteName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

