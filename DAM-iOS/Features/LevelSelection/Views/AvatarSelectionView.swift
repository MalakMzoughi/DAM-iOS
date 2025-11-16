//
//  AvatarSelectionView.swift
//  DAM-iOS
//
//  Avatar Selection Screen - Choose your assistant avatar before playing piano
//  Created by Apple Esprit on 13/11/2025
//

import SwiftUI

struct AvatarSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var userSession: UserSession
    @StateObject private var viewModel: AvatarSelectionViewModel
    
    let level: Level
    let playMode: PlayMode
    
    init(level: Level, playMode: PlayMode) {
        self.level = level
        self.playMode = playMode
        _viewModel = StateObject(wrappedValue: AvatarSelectionViewModel())
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image
                backgroundLayer
                
                VStack(spacing: 0) {
                    // HEADER: Back button and title
                    headerBar
                        .padding(.top, 20)
                    
                    Spacer().frame(height: 40)
                    
                    // TITLE: "Choose Your Assistant"
                    titleSection
                    
                    Spacer().frame(height: 30)
                    
                    // SELECTED AVATAR DISPLAY: Show selected avatar
                    if viewModel.selectedAvatar != nil || viewModel.useDefaultAvatar {
                        selectedAvatarDisplay
                            .padding(.horizontal, 40)
                            .padding(.bottom, 20)
                    }
                    
                    // AVATAR GRID: Available avatars
                    avatarGrid
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // CONTINUE BUTTON: Only enabled when avatar is selected
                    continueButton
                        .padding(.bottom, 40)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .onAppear {
            viewModel.loadAvatars(userSession: userSession)
        }
        .fullScreenCover(isPresented: $viewModel.showPianoView) {
            PianoView(level: level)
                .environmentObject(userSession)
        }
    }
    
    // MARK: - Background Layer
    private var backgroundLayer: some View {
        Image("bg_level1")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .blur(radius: 3)
            .overlay(
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
            )
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
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
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("Choose Your Assistant")
                .font(.system(size: 36, weight: .heavy))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
            
            Text("Select an avatar to help you learn")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Avatar Grid
    private var avatarGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                // Default level character (always available)
                DefaultAvatarCard(
                    level: level,
                    isSelected: viewModel.selectedAvatar == nil,
                    onSelect: {
                        viewModel.selectAvatar(nil)
                    }
                )
                
                // User's avatars
                ForEach(viewModel.availableAvatars) { avatar in
                    AvatarCard(
                        avatar: avatar,
                        isSelected: viewModel.selectedAvatar?.id == avatar.id,
                        onSelect: {
                            viewModel.selectAvatar(avatar)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Selected Avatar Display
    private var selectedAvatarDisplay: some View {
        VStack(spacing: 12) {
            Text("Selected Assistant")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            HStack(spacing: 20) {
                // Avatar Image
                if let avatar = viewModel.selectedAvatar {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .stroke(Color.yellow, lineWidth: 3)
                            )
                        
                        if let avatarUrl = avatar.readyPlayerMeAvatarUrl ?? avatar.readyPlayerMeGlbUrl {
                            let renderUrl = ReadyPlayerMeConfig.getRenderURL(avatarUrl: avatarUrl, scene: "fullbody-portrait-v1")
                            AsyncImage(url: URL(string: renderUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                case .empty:
                                    ProgressView()
                                        .frame(width: 90, height: 90)
                                case .failure:
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.7))
                                @unknown default:
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        } else if let imageUrl = avatar.avatarImageUrl, let url = URL(string: imageUrl) {
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
                                        .frame(width: 90, height: 90)
                                case .failure:
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.7))
                                @unknown default:
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // Avatar Name
                    Text(avatar.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                } else if viewModel.useDefaultAvatar {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .stroke(Color.yellow, lineWidth: 3)
                            )
                        
                        Image(level.islandAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                    }
                    
                    Text("Level Character")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                    )
            )
        }
    }
    
    // MARK: - Continue Button
    private var continueButton: some View {
        Button(action: {
            viewModel.confirmSelection(userSession: userSession)
        }) {
            Text("Continue to Piano")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: 300)
                .frame(height: 60)
                .background(
                    LinearGradient(
                        colors: viewModel.selectedAvatar != nil || viewModel.useDefaultAvatar
                            ? [Color(red: 1.0, green: 0.75, blue: 0.15), Color(red: 1.0, green: 0.5, blue: 0.0)]
                            : [Color.gray, Color.gray],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(viewModel.selectedAvatar == nil && !viewModel.useDefaultAvatar)
        .opacity(viewModel.selectedAvatar != nil || viewModel.useDefaultAvatar ? 1.0 : 0.6)
    }
}

// MARK: - Avatar Card
struct AvatarCard: View {
    let avatar: Avatar
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Avatar Image
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 180, height: 180)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.yellow : Color.white.opacity(0.5), lineWidth: isSelected ? 4 : 2)
                        )
                    
                    if let avatarUrl = avatar.readyPlayerMeAvatarUrl ?? avatar.readyPlayerMeGlbUrl {
                        let renderUrl = ReadyPlayerMeConfig.getRenderURL(avatarUrl: avatarUrl, scene: "fullbody-portrait-v1")
                        AsyncImage(url: URL(string: renderUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 160, height: 160)
                                    .clipShape(Circle())
                            case .empty:
                                ProgressView()
                                    .frame(width: 160, height: 160)
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
                                    .frame(width: 160, height: 160)
                                    .clipShape(Circle())
                            case .empty:
                                ProgressView()
                                    .frame(width: 160, height: 160)
                            case .failure:
                                fallbackAvatarImage
                            @unknown default:
                                fallbackAvatarImage
                            }
                        }
                    } else {
                        fallbackAvatarImage
                    }
                    
                    // Selection indicator
                    if isSelected {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.yellow)
                                    .background(Circle().fill(Color.white))
                                    .offset(x: 10, y: 10)
                            }
                        }
                        .frame(width: 180, height: 180)
                    }
                }
                
                // Avatar Name
                Text(avatar.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    private var fallbackAvatarImage: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 80))
            .foregroundColor(.white.opacity(0.7))
    }
}

// MARK: - Default Avatar Card
struct DefaultAvatarCard: View {
    let level: Level
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Level Character Image
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 180, height: 180)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.yellow : Color.white.opacity(0.5), lineWidth: isSelected ? 4 : 2)
                        )
                    
                    Image(level.islandAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .clipShape(Circle())
                    
                    // Selection indicator
                    if isSelected {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.yellow)
                                    .background(Circle().fill(Color.white))
                                    .offset(x: 10, y: 10)
                            }
                        }
                        .frame(width: 180, height: 180)
                    }
                }
                
                // Default Name
                Text("Level Character")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
        }
    }
}

