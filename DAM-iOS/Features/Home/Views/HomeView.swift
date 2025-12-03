//
//  HomeView.swift
//  DAM-iOS
//
//  Island Map Implementation
//

import SwiftUI
import AVFoundation

struct HomeView: View {

    // ---------------------------------------------------------
    // ENVIRONMENT
    // ---------------------------------------------------------
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var router: AppRouter

    // ---------------------------------------------------------
    // VIEW MODEL
    // ---------------------------------------------------------
    @StateObject private var viewModel = HomeScreenViewModel()

    // ---------------------------------------------------------
    // ALERTS
    // ---------------------------------------------------------
    @State private var showLockedAlert = false
    @State private var showGuestAlert = false
    @State private var showAddAvatar = false
    @State private var showMusicRecognition = false
    
    // ---------------------------------------------------------
    // DRAWER
    // ---------------------------------------------------------
    @State private var showDrawer = false

    // ---------------------------------------------------------
    // MAP CONSTANTS - Will use screen size
    // ---------------------------------------------------------
    @State private var screenSize: CGSize = .zero

    // ---------------------------------------------------------
    // BODY
    // ---------------------------------------------------------
    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                // FIXED MAP AREA - No scrolling, fits screen
                GeometryReader { geometry in
                    ScrollView {
                        ZStack {
                            decorativeElementsLayer
                            islandsLayer
                            bannerLayer
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .onAppear {
                            screenSize = geometry.size
                        }
                    }
                    .refreshable {
                        viewModel.load(userSession: userSession)
                    }
                }
            }
            
            // HEADER - Overlay on top with proper z-index
            VStack {
                let currentProfile = userSession.profile
                let currentAvatar = userSession.activeAvatar
                let avatarAccentColor = currentAvatar?.accentColor() ?? "🎹".toAvatarAccentColor()
                
                EnhancedHomeHeaderView(
                    profile: currentProfile,
                    isLoggedIn: userSession.isLoggedIn,
                    totalStars: viewModel.totalStars,
                    activeAvatar: currentAvatar,
                    accentColor: avatarAccentColor,
                    onAvatarTap: { showDrawer = true }
                )
                .padding(EdgeInsets(top: 8, leading: 50, bottom: 8, trailing: 50))
                
                Spacer()
            }
            .zIndex(1000)
            
            // Drawer overlay
            if showDrawer {
                HomeDrawerView(
                    userName: userSession.profile.name,
                    avatarImageUrl: userSession.activeAvatar?.avatarImageUrl,
                    avatarName: userSession.activeAvatar?.name,
                    fallbackEmoji: "🎹",
                    isLoggedIn: userSession.isLoggedIn,
                    accentColor: userSession.activeAvatar?.accentColor() ?? "🎹".toAvatarAccentColor(),
                    onProfileClick: {
                        showDrawer = false
                        router.current = .profile
                    },
                    onRecognizeClick: {
                        showDrawer = false
                        showMusicRecognition = true
                    },
                    onAddAvatarClick: {
                        showDrawer = false
                        showAddAvatar = true
                    },
                    onClose: {
                        showDrawer = false
                    }
                )
                .transition(.move(edge: .leading))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDrawer)
                .zIndex(2000)
            }
            
        }
        .overlay(alignment: .topTrailing) {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.4))
                    )
                    .padding(24)
                    .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $showAddAvatar) {
            AvatarNameInputView()
                .environmentObject(userSession)
        }
        .sheet(isPresented: $showMusicRecognition) {
            MusicRecognitionView()
        }
        .onAppear {
            viewModel.load(userSession: userSession)
        }
        .alert("Level Locked", isPresented: $showLockedAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Login Required", isPresented: $showGuestAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Guests can only play Level 1.")
        }
    }

    // ---------------------------------------------------------
    // BACKGROUND - Ocean blue gradient
    // ---------------------------------------------------------
    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.6, blue: 0.9),
                Color(red: 0.1, green: 0.5, blue: 0.85)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // ---------------------------------------------------------
    // BANNER - Top center "TUNE ISLAND MUSICAL ADVENTURE"
    // ---------------------------------------------------------
    private var bannerLayer: some View {
        let width = screenSize.width > 0 ? screenSize.width : 1024
        
        return VStack {
            ZStack {
                // Red banner ribbon shape
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color(red: 0.8, green: 0.1, blue: 0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 600, height: 180)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    // Musical notes decoration
                    HStack(spacing: 20) {
                        Text("🎼")
                            .font(.system(size: 50))
                        Text("TUNE ISLAND")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white)
                        Text("🎵")
                            .font(.system(size: 50))
                    }
                    
                    Text("— MUSICAL —")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("ADVENTURE")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .position(x: width / 2, y: 150)
            
            Spacer()
        }
    }

    // ---------------------------------------------------------
    // DECORATIVE ELEMENTS - Cleaner design
    // ---------------------------------------------------------
    private var decorativeElementsLayer: some View {
        ZStack {
            // Palm trees
            palmTree(at: CGPoint(x: 0.08, y: 0.52))
            palmTree(at: CGPoint(x: 0.93, y: 0.24))
            
            // Sailing ship - top left
            ship(at: CGPoint(x: 0.10, y: 0.15))
            
            // Pirate ship - right side
            pirateShip(at: CGPoint(x: 0.87, y: 0.78))
            
            // Sea monster - center bottom
            seaMonster(at: CGPoint(x: 0.52, y: 0.88))
            
            // Small rock islands for variety
            rockIsland(at: CGPoint(x: 0.05, y: 0.35))
            rockIsland(at: CGPoint(x: 0.58, y: 0.52))
            
            // Musical notes floating around
            musicalNotes(at: CGPoint(x: 0.45, y: 0.95))
            musicalNotes(at: CGPoint(x: 0.65, y: 0.15))
            
            // Subtle wave effects
            waves()
        }
    }
    
    private func palmTree(at position: CGPoint) -> some View {
        let width = screenSize.width > 0 ? screenSize.width : 1024
        let height = screenSize.height > 0 ? screenSize.height : 768
        
        return Text("🌴")
            .font(.system(size: 100))
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .position(x: position.x * width, y: position.y * height)
    }
    
    private func ship(at position: CGPoint) -> some View {
        let width = screenSize.width > 0 ? screenSize.width : 1024
        let height = screenSize.height > 0 ? screenSize.height : 768
        
        return ZStack {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 45, height: 45)
                    Text("1")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("⛵")
                    .font(.system(size: 70))
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .position(x: position.x * width, y: position.y * height)
    }
    
    private func pirateShip(at position: CGPoint) -> some View {
        let width = screenSize.width > 0 ? screenSize.width : 1024
        let height = screenSize.height > 0 ? screenSize.height : 768
        
        return HStack(spacing: -10) {
            Text("🏴‍☠️")
                .font(.system(size: 50))
            Text("⛵")
                .font(.system(size: 80))
        }
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .position(x: position.x * width, y: position.y * height)
    }
    
    private func seaMonster(at position: CGPoint) -> some View {
        let width = screenSize.width > 0 ? screenSize.width : 1024
        let height = screenSize.height > 0 ? screenSize.height : 768
        
        return Text("🐉")
            .font(.system(size: 160))
            .rotationEffect(.degrees(-15))
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
            .position(x: position.x * width, y: position.y * height)
    }
    
    private func rockIsland(at position: CGPoint) -> some View {
        let width = screenSize.width > 0 ? screenSize.width : 1024
        let height = screenSize.height > 0 ? screenSize.height : 768
        
        return ZStack {
            Ellipse()
                .fill(Color.cyan.opacity(0.25))
                .frame(width: 110, height: 70)
            
            Text("🪨")
                .font(.system(size: 55))
        }
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        .position(x: position.x * width, y: position.y * height)
    }
    
    private func musicalNotes(at position: CGPoint) -> some View {
        let width = screenSize.width > 0 ? screenSize.width : 1024
        let height = screenSize.height > 0 ? screenSize.height : 768
        
        return HStack(spacing: 8) {
            Text("♪")
            Text("♫")
            Text("♪")
        }
        .font(.system(size: 35))
        .foregroundColor(.yellow.opacity(0.8))
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        .position(x: position.x * width, y: position.y * height)
    }
    
    private func waves() -> some View {
        let width = screenSize.width > 0 ? screenSize.width : 1024
        let height = screenSize.height > 0 ? screenSize.height : 768
        
        return ZStack {
            ForEach(0..<25, id: \.self) { i in
                let randomSeed = Double(i) * 123.456
                Text("〰️")
                    .font(.system(size: 25))
                    .foregroundColor(.white.opacity(0.3))
                    .position(
                        x: CGFloat((randomSeed * 7).truncatingRemainder(dividingBy: Double(width))),
                        y: CGFloat((randomSeed * 11).truncatingRemainder(dividingBy: Double(height)))
                    )
            }
        }
    }

    // ---------------------------------------------------------
    // ISLANDS LAYER - Character islands with level cards
    // ---------------------------------------------------------
    private var islandsLayer: some View {
        ForEach(viewModel.levels) { level in
            let item = viewModel.progressById[level.id]
            let isUnlocked = item?.unlocked ?? false
            let stars = item?.starsUnlocked ?? 0

            IslandNodeView(
                level: level,
                isUnlocked: isUnlocked,
                stars: stars,
                position: getIslandPosition(for: level)
            ) {
                handleLevelTap(level, isUnlocked: isUnlocked)
            }
        }
    }

    // Island positions from backend mapPosition (normalized 0.0-1.0)
    private func getIslandPosition(for level: Level) -> CGPoint {
        let width = screenSize.width > 0 ? screenSize.width : 1024
        let height = screenSize.height > 0 ? screenSize.height : 768
        
        // Use backend mapPosition directly - it's already normalized
        return CGPoint(
            x: CGFloat(level.mapPosition.x) * width,
            y: CGFloat(level.mapPosition.y) * height + 60
        )
    }
    
    private func handleLevelTap(_ level: Level, isUnlocked: Bool) {
        if !userSession.isLoggedIn && level.order != 1 {
            showGuestAlert = true
            return
        }

        if !isUnlocked {
            showLockedAlert = true
            return
        }

        router.navigate(to: .level(level))
    }
}

// ---------------------------------------------------------
// ISLAND NODE VIEW - Using character images from backend
// ---------------------------------------------------------
struct IslandNodeView: View {

    let level: Level
    let isUnlocked: Bool
    let stars: Int
    let position: CGPoint
    let onTap: () -> Void

    var body: some View {
        ZStack {
            // Water ripple effect (bottom layer) - smaller
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cyan.opacity(0.25),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
            
            VStack(spacing: -30) {
                // Level number badge (top) - smaller
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color(red: 1.0, green: 0.6, blue: 0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 45, height: 45)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Text("\(level.order)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Main island platform - smaller
                ZStack {
                    // Shore/water edge
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.85, blue: 0.95).opacity(0.5),
                                    Color(red: 0.2, green: 0.7, blue: 0.9).opacity(0.2)
                                ],
                                center: .center,
                                startRadius: 15,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 100)
                        .offset(y: 15)
                    
                    // Island sand using image from backend or gradient fallback
                    if let islandUrl = URL(string: level.islandImageUrl) {
                        AsyncImage(url: islandUrl) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 90)
                                    .clipShape(Ellipse())
                                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                            case .failure(_), .empty:
                                // Fallback to gradient
                                Ellipse()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 1.0, green: 0.9, blue: 0.3),
                                                Color(red: 0.95, green: 0.8, blue: 0.2),
                                                Color(red: 0.85, green: 0.7, blue: 0.15)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 150, height: 90)
                                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                            @unknown default:
                                Ellipse()
                                    .fill(Color.yellow)
                                    .frame(width: 150, height: 90)
                            }
                        }
                    } else {
                        Ellipse()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.9, blue: 0.3),
                                        Color(red: 0.95, green: 0.8, blue: 0.2)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 150, height: 90)
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                    
                    // Character from backend or lock
                    Button(action: onTap) {
                        VStack(spacing: 8) {
                            if isUnlocked {
                                // Use boss character image from backend
                                if let bossUrl = level.bossUrl, let url = URL(string: bossUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 90, height: 90)
                                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        case .failure(_), .empty:
                                            // Fallback to musical note emoji
                                            Text("🎵")
                                                .font(.system(size: 90))
                                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        @unknown default:
                                            Text("🎵")
                                                .font(.system(size: 90))
                                        }
                                    }
                                } else {
                                    // No boss URL, use musical note
                                    Text("🎵")
                                        .font(.system(size: 90))
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                }
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Level title
                            Text(level.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(isUnlocked ? .black : .gray)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(width: 180)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.9))
                                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                )
                        }
                    }
                    .disabled(!isUnlocked)
                    
                    // Stars display for unlocked levels
                    if isUnlocked && stars > 0 {
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { i in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(i < stars ? Color.yellow : Color.gray.opacity(0.4))
                            }
                        }
                        .padding(6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                        )
                        .offset(y: 85)
                    }
                }
            }
        }
        .frame(width: 320, height: 320)
        .position(position)
    }
}

// ---------------------------------------------------------
// PREVIEW
// ---------------------------------------------------------
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(UserSession())
            .environmentObject(AppRouter())
            .previewInterfaceOrientation(.landscapeRight)
    }
}
