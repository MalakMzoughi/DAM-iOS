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
    // MAP CONSTANTS
    // ---------------------------------------------------------
    @State private var screenSize: CGSize = .zero
    @State private var floatOffset: CGFloat = 0

    // ---------------------------------------------------------
    // BODY
    // ---------------------------------------------------------
    var body: some View {
        ZStack {
            backgroundLayer
            VStack(spacing: 0) {

                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    ZStack {
                        islandsLayer
                        .frame(width: UIScreen.main.bounds.width * 2,
                            height: UIScreen.main.bounds.height * 1.5)
                            .clipped()
                    }
                    .frame(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 1.5)
                }
                .refreshable {
                    viewModel.load(userSession: userSession)
                }
            }
            
            // HEADER
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
    // BACKGROUND
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
    // ISLANDS LAYER
    // ---------------------------------------------------------
    private var islandsLayer: some View {
        ZStack {
            ForEach(viewModel.levels) { level in
                let progress = viewModel.progressById[level.id]
                let isUnlocked = progress?.unlocked ?? false
                let stars = progress?.starsUnlocked ?? 0

                let pos = IOSMapPositions.positions[level.order] ?? CGPoint(x: 0.5, y: 0.5)

                let floatY = sin(Float(level.order) * 0.5 + Float(floatOffset)) * 8

                IslandNodeView(
                    level: level,
                    isUnlocked: isUnlocked,
                    stars: stars,
                    scale: 1.0
                ) {
                    handleLevelTap(level, isUnlocked: isUnlocked)
                }
                .position(
                    x: pos.x * 2800,
                    y: pos.y * 1800 + CGFloat(floatY)
                )
                .zIndex(Double(level.order))
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
// ISLAND NODE VIEW
// ---------------------------------------------------------
struct IslandNodeView: View {

    let level: Level
    let isUnlocked: Bool
    let stars: Int
    let scale: CGFloat
    let onTap: () -> Void

    var body: some View {
        ZStack {
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
                    
                    Text("\(level.order)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }

                ZStack {
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

                    if let islandUrl = URL(string: level.islandImageUrl) {
                        AsyncImage(url: islandUrl) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 90)
                                    .clipShape(Ellipse())
                            default:
                                Ellipse()
                                    .fill(Color.yellow)
                                    .frame(width: 150, height: 90)
                            }
                        }
                    }

                    Button(action: onTap) {
                        VStack(spacing: 8) {
                            if isUnlocked {
                                if let bossUrl = level.bossUrl, let url = URL(string: bossUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 90, height: 90)
                                        default:
                                            Text("🎵").font(.system(size: 90))
                                        }
                                    }
                                } else {
                                    Text("🎵").font(.system(size: 90))
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

                            Text(level.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(isUnlocked ? .black : .gray)
                                .lineLimit(2)
                                .frame(width: 180)
                        }
                    }
                }
            }
        }
        .scaleEffect(scale)
        .fixedSize()
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

// ---------------------------------------------------------
// GIF BACKGROUND PROVIDER
// ---------------------------------------------------------
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
    enum Source { case data(Data), fileURL(URL) }
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

        webView.loadHTMLString(GIFBackgroundView.htmlWrapper(base64: base64), baseURL: nil)
    }

    private func encodedData() -> String? {
        switch source {
        case .data(let d): return d.base64EncodedString()
        case .fileURL(let u): return try? Data(contentsOf: u).base64EncodedString()
        }
    }

    private static func htmlWrapper(base64: String) -> String {
        """
        <html><head><style>
        html,body { margin:0;padding:0;background:transparent;overflow:hidden;height:100%;}
        img { width:100%;height:100%;object-fit:cover;}
        </style></head>
        <body><img src='data:image/gif;base64,\(base64)'/></body></html>
        """
    }
}

// ---------------------------------------------------------
// ZIGZAG ISLAND POSITIONS (THE ONLY CHANGE YOU ASKED FOR)
// ---------------------------------------------------------
struct IOSMapPositions {
    static let positions: [Int: CGPoint] = [
        // A single snake going left → right with up/down zigzags

        1: CGPoint(x: 0.15, y: 0.22), // Level 1 – left, higher
        2: CGPoint(x: 0.30, y: 0.45), // Level 2 – more right, lower
        3: CGPoint(x: 0.45, y: 0.30), // Level 3 – more right, higher
        4: CGPoint(x: 0.60, y: 0.55), // Level 4 – more right, lower
        5: CGPoint(x: 0.75, y: 0.35), // Level 5 – more right, higher
        6: CGPoint(x: 0.90, y: 0.60)  // Level 6 – far right, lower
    ]
}

