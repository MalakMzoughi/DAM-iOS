//
//  LevelIntroDialog.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 23/11/2025.
//

import SwiftUI
import UIKit

struct LevelIntroDialogView: View {
    let level: Level
    let onChooseSublevel: () -> Void
    
    @State private var typedText = ""
    @State private var showStartButton = false
    @State private var allTextShown = false
    @State private var isVisible = false

    private var heroAssetName: String? {
        switch level.theme {
        case "Batman": return "heroBatman"
        case "Spider-Man": return "heroSpiderman"
        case "My Neighbour Totoro": return "heroTotoro"
        case "Pokémon", "Pokemon": return "heroPokemon"
        case "Marvel-Heroes": return "heroAvengers"
        case "HunterxHunter": return "heroHXH"
        default: return nil
        }
    }

    private var heroRemoteURL: URL? {
        if let boss = URL.backendAsset(from: level.bossUrl) {
            return boss
        }
        if let background = URL.backendAsset(from: level.backgroundUrl) {
            return background
        }
        return URL.backendAsset(from: level.islandImageUrl)
    }

    @ViewBuilder
    private var heroImageView: some View {
        if let assetName = heroAssetName, UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFit()
        } else if let url = heroRemoteURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    Image(systemName: "sparkles")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.4))
                case .empty:
                    ProgressView().tint(.white)
                @unknown default:
                    Color.clear
                }
            }
        } else {
            Image("heroBatman")
                .resizable()
                .scaledToFit()
        }
    }

    var body: some View {
        ZStack {
            // BACKDROP
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.35),
                    Color.blue.opacity(0.5),
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // MAIN CARD
            VStack(spacing: 22) {
                Text("MISSION BRIEFING")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top)

                // HERO + STORY
                HStack(spacing: 20) {
                    // HERO IMAGE
                    heroImageView
                        .frame(width: 170, height: 250)
                        .shadow(color: .blue.opacity(0.5), radius: 12, x: 0, y: 6)

                    // STORY (typewriter)
                    VStack(alignment: .leading, spacing: 12) {
                        ScrollView {
                            Text(typedText)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .lineSpacing(4)
                                .padding(.horizontal, 6)
                        }
                        .frame(height: 200)

                        // SKIP BUTTON
                        if !allTextShown {
                            Button(action: skipText) {
                                Text("Skip")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 18)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(10)
                            }
                            .animation(.spring(), value: allTextShown)
                        }
                    }
                }

                // START BUTTON
                if showStartButton {
                    Button(action: onChooseSublevel) {
                        HStack {
                            Text("CHOOSE SUBLEVEL")
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(.white)
                            Text("🎯")
                                .font(.system(size: 20))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 40)
                        .background(
                            LinearGradient(
                                colors: [.blue, .green, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .blue.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding()
            .background(Color.white.opacity(0.1).blur(radius: 6))
            .cornerRadius(20)
            .padding(.horizontal, 40)
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
        }
        .onAppear {
            isVisible = true
            startTypewriter()
        }
    }

    // MARK: - Typewriter effect
    private func startTypewriter() {
        typedText = ""
        showStartButton = false
        allTextShown = false

        let chars = Array(level.story)
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // Wait 300ms for entrance animation

            for char in chars {
                if allTextShown { return } // Skip interrupted
                typedText.append(char)
                try? await Task.sleep(nanoseconds: 35_000_000)
            }

            allTextShown = true
            withAnimation { showStartButton = true }
        }
    }

    private func skipText() {
        typedText = level.story
        allTextShown = true
        withAnimation { showStartButton = true }
    }
}
