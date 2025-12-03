//
//  LevelSelectionView.swift
//  DAM-iOS
//
//  Updated with proper navigation to game screen
//

import SwiftUI

struct LevelSelectionView: View {
    @StateObject private var viewModel: LevelSelectionViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var userSession: UserSession
    
    let level: Level
    let onStartGame: () -> Void  // Callback to parent coordinator
    
    init(level: Level, onStartGame: @escaping () -> Void) {
        self.level = level
        self.onStartGame = onStartGame
        _viewModel = StateObject(wrappedValue: LevelSelectionViewModel(level: level))
    }
    
    @State private var showSublevels: Bool = false
    @State private var selectedMode: PianoMode? = nil
    private let subRepo = SublevelRepository()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundLayer
                
                VStack(spacing: 0) {
                    // TOP: Back Button & ribbon
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
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    
                    levelHeaderRibbon
                        .padding(.top, 10)
                    
                    Spacer().frame(height: 20)
                    
                    // CENTER: Speech + Character Island
                    VStack(spacing: 20) {
                        speechBubble
                        characterImage
                    }
                    
                    Spacer().frame(height: 30)
                    
                    // BOTTOM: Play Mode Buttons
                    HStack(spacing: 100) {
                            EnhancedPlayModeButton(
                                icon: "pianoKeys",
                                title: "Play on App\nPiano",
                                colors: [
                                    Color(red: 1.0, green: 0.75, blue: 0.15),
                                    Color(red: 1.0, green: 0.5, blue: 0.0)
                                ],
                                action: {
                                    selectedMode = .appPiano
                                    showSublevels = true
                                }
                            )
                        
                        EnhancedPlayModeButton(
                            icon: "realPiano",
                            title: "Play on My\nReal Piano",
                            colors: [
                                Color(red: 0.35, green: 0.75, blue: 1.0),
                                Color(red: 0.55, green: 0.45, blue: 0.95)
                            ],
                            action: {
                                selectedMode = .realPiano
                                showSublevels = true
                            },
                            isDisabled: false
                        )
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .sheet(isPresented: $showSublevels) {
            SublevelListView(
                level: level,
                levelId: level.id,
                userId: userSession.isLoggedIn ? userSession.profile.id : nil,
                preselectedMode: selectedMode
            ) { sub, mode in
                print("Selected sublevel: \(sub.id) with mode: \(mode)")
                onStartGame()
            }
        }
    }
    
    // MARK: - Background Layer (Dynamic)
    private var backgroundLayer: some View {
        Group {
            if let urlString = level.backgroundUrl,
               let url = URL(string: urlString)
            {
                AsyncImage(url: url) { img in
                    img.resizable()
                } placeholder: {
                    Color.black.opacity(0.4)
                }
            } else {
                Color.black.opacity(0.4)
            }
        }
        .scaledToFill()
        .blur(radius: 3)
        .overlay(Color.black.opacity(0.1))
    }
    
    // MARK: - Header Ribbon
    private var levelHeaderRibbon: some View {
        ZStack {
            HStack(spacing: 0) {
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(90))
                    .foregroundColor(Color(red: 0.8, green: 0.15, blue: 0.2))
                    .frame(width: 12)
                    .offset(x: 6)
                
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
                    .frame(height: 70)
                
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(-90))
                    .foregroundColor(Color(red: 0.8, green: 0.15, blue: 0.2))
                    .frame(width: 12)
                    .offset(x: -6)
            }
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 4) {
                Text("Level \(level.order):")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                
                Text(level.title)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
        }
        .frame(maxWidth: 340)
    }
    
    // MARK: - Speech Bubble
    private var speechBubble: some View {
        VStack(spacing: 0) {
            Triangle()
                .fill(Color.white)
                .frame(width: 30, height: 15)
                .rotationEffect(.degrees(180))
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: -3)
                .offset(y: 1)
            
            Text("How will you unleash musical\npower today, hero?")
                .font(.system(size: 20, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                )
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Character Island Image (dynamic)
    private var characterImage: some View {
        Group {
            if let url = URL(string: level.islandImageUrl) {
                AsyncImage(url: url) { img in
                    img.resizable()
                } placeholder: {
                    ProgressView()
                }
            } else {
                Color.clear
            }
        }
        .scaledToFit()
        .frame(width: 320, height: 320)
        .shadow(color: .black.opacity(0.35), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Enhanced Play Mode Button (unchanged)
struct EnhancedPlayModeButton: View {
    let icon: String
    let title: String
    let colors: [Color]
    let action: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 5)
                    )
                
                VStack(spacing: 18) {
                    Group {
                        if icon == "pianoKeys" {
                            VStack(spacing: 3) {
                                HStack(spacing: 4) {
                                    ForEach(0..<6) { _ in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.white)
                                            .frame(width: 10, height: 32)
                                    }
                                }
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 10)
                                    .cornerRadius(4)
                            }
                        } else {
                            HStack(spacing: 10) {
                                VStack(spacing: 3) {
                                    Capsule()
                                        .fill(Color.white)
                                        .frame(width: 14, height: 24)
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 22, height: 4)
                                        .cornerRadius(2)
                                }
                                
                                VStack(spacing: 2) {
                                    HStack(spacing: 2) {
                                        ForEach(0..<4) { _ in
                                            RoundedRectangle(cornerRadius: 1)
                                                .fill(Color.white)
                                                .frame(width: 6, height: 18)
                                        }
                                    }
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 32, height: 6)
                                        .cornerRadius(2)
                                }
                            }
                        }
                    }
                    .frame(height: 50)
                    
                    Text(title)
                        .font(.system(size: 19, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                        .lineSpacing(4)
                }
            }
        }
        .opacity(isDisabled ? 0.65 : 1.0)
        .disabled(isDisabled)
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
