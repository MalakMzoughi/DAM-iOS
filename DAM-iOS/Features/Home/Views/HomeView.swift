//
//  HomeView.swift
//  DAM-iOS
//
//  Island Map Implementation
//

import SwiftUI
import AVFoundation
import UIKit
import WebKit

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
    private let islandLayout = IslandLayoutGuide()

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
        Group {
            if let source = OceanBackgroundProvider.source {
                GIFBackgroundView(source: source)
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.6, blue: 0.9),
                        Color(red: 0.1, green: 0.5, blue: 0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
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
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                // Palm trees framing the scene
                palmTree(in: size, at: CGPoint(x: 0.10, y: 0.30))
                palmTree(in: size, at: CGPoint(x: 0.90, y: 0.28))
                palmTree(in: size, at: CGPoint(x: 0.12, y: 0.78))
                palmTree(in: size, at: CGPoint(x: 0.88, y: 0.80))

                // Sailing markers
                ship(in: size, at: CGPoint(x: 0.12, y: 0.12), badge: 1)
                pirateShip(in: size, at: CGPoint(x: 0.87, y: 0.84))

                // Atmosphere
                seaMonster(in: size, at: CGPoint(x: 0.50, y: 0.92))
                rockIsland(in: size, at: CGPoint(x: 0.32, y: 0.50))
                rockIsland(in: size, at: CGPoint(x: 0.68, y: 0.58))

                // Floating music cues
                musicalNotes(in: size, at: CGPoint(x: 0.52, y: 0.10))
                musicalNotes(in: size, at: CGPoint(x: 0.70, y: 0.70))

                waves(in: size)
            }
        }
    }
    
    private func palmTree(in size: CGSize, at position: CGPoint) -> some View {
        let width = max(size.width, 1)
        let height = max(size.height, 1)

        return Text("🌴")
            .font(.system(size: 100))
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .position(x: position.x * width, y: position.y * height)
    }
    
    private func ship(in size: CGSize, at position: CGPoint, badge: Int) -> some View {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 48, height: 48)
                Text("\(badge)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            Text("⛵")
                .font(.system(size: 70))
        }
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .position(x: position.x * width, y: position.y * height)
    }
    
    private func pirateShip(in size: CGSize, at position: CGPoint) -> some View {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        
        return HStack(spacing: -10) {
            Text("🏴‍☠️")
                .font(.system(size: 50))
            Text("⛵")
                .font(.system(size: 80))
        }
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .position(x: position.x * width, y: position.y * height)
    }
    
    private func seaMonster(in size: CGSize, at position: CGPoint) -> some View {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        
        return Text("🐉")
            .font(.system(size: 150))
            .rotationEffect(.degrees(-10))
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
            .position(x: position.x * width, y: position.y * height)
    }
    
    private func rockIsland(in size: CGSize, at position: CGPoint) -> some View {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        
        return ZStack {
            Ellipse()
                .fill(Color.cyan.opacity(0.25))
                .frame(width: 120, height: 80)
            
            Text("🪨")
                .font(.system(size: 55))
        }
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        .position(x: position.x * width, y: position.y * height)
    }
    
    private func musicalNotes(in size: CGSize, at position: CGPoint) -> some View {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        
        return HStack(spacing: 8) {
            Text("♪")
            Text("♫")
            Text("♪")
        }
        .font(.system(size: 30))
        .foregroundColor(.yellow.opacity(0.8))
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        .position(x: position.x * width, y: position.y * height)
    }
    
    private func waves(in size: CGSize) -> some View {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        
        return ZStack {
            ForEach(0..<25, id: \.self) { i in
                let randomSeed = Double(i) * 123.456
                Text("〰️")
                    .font(.system(size: 25))
                    .foregroundColor(.white.opacity(0.25))
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
        let scale = islandLayout.scale(for: screenSize)

        return ZStack {
            ForEach(Array(viewModel.levels.enumerated()), id: \.element.id) { index, element in
                let level = element
                let item = viewModel.progressById[level.id]
                let isUnlocked = item?.unlocked ?? false
                let stars = item?.starsUnlocked ?? 0

                IslandNodeView(
                    level: level,
                    isUnlocked: isUnlocked,
                    stars: stars,
                    scale: scale
                ) {
                    handleLevelTap(level, isUnlocked: isUnlocked)
                }
                .position(
                    islandLayout.position(
                        for: index,
                        total: viewModel.levels.count,
                        in: screenSize
                    )
                )
            }
        }
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
    let scale: CGFloat
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
        .scaleEffect(scale)
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

private enum OceanBackgroundProvider {
    static var source: GIFBackgroundView.Source? {
        if let asset = NSDataAsset(name: "oceanbackground") {
            return .data(asset.data)
        }

        if let url = Bundle.main.url(forResource: "ocean", withExtension: "gif") {
            return .fileURL(url)
        }

        return nil
    }
}

private struct GIFBackgroundView: UIViewRepresentable {
    enum Source {
        case data(Data)
        case fileURL(URL)
    }

    let source: Source

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        configure(webView)
        loadContent(on: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadContent(on: uiView)
    }

    private func configure(_ webView: WKWebView) {
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.backgroundColor = .clear
    }

    private func loadContent(on webView: WKWebView) {
        guard let base64 = encodedData() else {
            webView.loadHTMLString("", baseURL: nil)
            return
        }

        let html = GIFBackgroundView.htmlWrapper(base64: base64)
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func encodedData() -> String? {
        switch source {
        case .data(let data):
            return data.base64EncodedString()
        case .fileURL(let url):
            return try? Data(contentsOf: url).base64EncodedString()
        }
    }

    private static func htmlWrapper(base64: String) -> String {
        """
        <html>
            <head>
                <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0'>
                <style>
                    html, body {
                        margin: 0;
                        padding: 0;
                        background: transparent;
                        overflow: hidden;
                        height: 100%;
                    }
                    img {
                        width: 100%;
                        height: 100%;
                        object-fit: cover;
                    }
                </style>
            </head>
            <body>
                <img src='data:image/gif;base64,\(base64)' alt='ocean'/>
            </body>
        </html>
        """
    }
}

private struct IslandLayoutGuide {
    let columns: Int = 3
    let horizontalPadding: CGFloat = 120
    let topInset: CGFloat = 290
    let bottomInset: CGFloat = 140
    let firstRowLowering: CGFloat = 60

    func position(for index: Int, total: Int, in size: CGSize) -> CGPoint {
        guard size.width > 0 && size.height > 0 else {
            let fallbackX = 200 + CGFloat(index % columns) * 220
            let fallbackY = 220 + CGFloat(index / columns) * 200
            return CGPoint(x: fallbackX, y: fallbackY)
        }

        let rows = max(1, Int(ceil(Double(total) / Double(columns))))
        let column = index % columns
        let row = index / columns

        let availableWidth = max(0, size.width - (horizontalPadding * 2))
        let columnSpacing = columns > 1 ? availableWidth / CGFloat(columns - 1) : 0
        let xPosition: CGFloat
        if columns == 1 {
            xPosition = size.width / 2
        } else {
            xPosition = horizontalPadding + CGFloat(column) * columnSpacing
        }

        let availableHeight = max(0, size.height - topInset - bottomInset)
        let rowSpacing = rows > 1 ? availableHeight / CGFloat(rows - 1) : 0
        let rowOffset = row == 0 ? firstRowLowering : 0
        let yPosition = topInset + CGFloat(row) * rowSpacing + rowOffset

        return CGPoint(x: xPosition, y: yPosition)
    }

    func scale(for size: CGSize) -> CGFloat {
        guard size.width > 0 else { return 1.0 }
        let referenceWidth: CGFloat = 1024
        let ratio = size.width / referenceWidth
        let minScale: CGFloat = 0.75
        let maxScale: CGFloat = 1.15
        return min(max(ratio, minScale), maxScale)
    }
}
