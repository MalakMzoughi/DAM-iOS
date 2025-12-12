//
//  SublevelListView.swift
//  DAM-iOS
//
//  A dialog showing sublevels for a level with mode selection (mirrors Android SublevelSelectionDialog)
//

import SwiftUI
import UIKit

struct SublevelListView: View {
    @StateObject private var viewModel = SublevelListViewModel()
    let level: Level
    let levelId: String
    let userId: String?
    let preselectedMode: PianoMode?
    // Now returns the selected sublevel AND the chosen play mode
    let onSelect: (Sublevel, PianoMode) -> Void
    @Environment(\.presentationMode) private var presentationMode

    @State private var selectedMode: PianoMode? = nil
    @State private var selectedSublevel: Sublevel? = nil

    private var themePalette: SublevelThemePalette {
        SublevelThemePalette(level: level)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: themePalette.backgroundGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            heroBackdropImage
                .frame(width: 260)
                .opacity(0.12)
                .offset(y: -200)

            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text(level.title.uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Choose Your Strategy")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white)
                }

                Divider()
                    .background(Color.white.opacity(0.25))

                contentView
            }
            .padding(28)
            .background(.thinMaterial)
            .cornerRadius(32)
            .padding(.horizontal, 24)
        }
        .task {
            await viewModel.loadSublevels(for: levelId, userId: userId)
            // Pre-select the mode that was clicked on the level selection screen
            if let mode = preselectedMode {
                selectedMode = mode
            }
            if selectedSublevel == nil {
                selectedSublevel = viewModel.sublevels.first(where: { $0.unlocked ?? true }) ?? viewModel.sublevels.first
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            ProgressView("Loading missions...")
                .tint(themePalette.accent)
                .foregroundColor(.white)
        } else if let msg = viewModel.errorMessage {
            VStack(spacing: 12) {
                Text(msg)
                    .foregroundColor(.white)
                Button("Retry") {
                    Task { await viewModel.loadSublevels(for: levelId, userId: userId) }
                }
                .buttonStyle(.borderedProminent)
                .tint(themePalette.accent)
            }
        } else if viewModel.sublevels.isEmpty {
            Text("No missions are available yet. Check back soon!")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        } else {
            VStack(spacing: 16) {
                instrumentPicker
                Divider().background(Color.white.opacity(0.15))
                missionCarousel
                actionButtons
            }
        }
    }

    private var instrumentPicker: some View {
        VStack(spacing: 12) {
            Text("Choose Your Instrument")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 16) {
                ModeToggleButton(label: "App Piano", emoji: "🎹", isSelected: selectedMode == .appPiano, accent: themePalette.accent) {
                    selectedMode = .appPiano
                }

                ModeToggleButton(label: "My Piano", emoji: "🎼", isSelected: selectedMode == .realPiano, accent: themePalette.accent) {
                    selectedMode = .realPiano
                }
            }
        }
    }

    private var missionCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select a Mission")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(viewModel.sublevels) { s in
                        VStack(spacing: 8) {
                            Button(action: {
                                selectedSublevel = s
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(circleFill(for: s))
                                        .frame(width: 80, height: 80)
                                        .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: selectedSublevel?.id == s.id ? 4 : 2))

                                    Text("\(s.index)")
                                        .font(.system(size: 26, weight: .heavy))
                                        .foregroundColor(.white)
                                        .opacity((s.unlocked ?? true) ? 1 : 0.4)
                                }
                            }
                            .disabled(!(s.unlocked ?? true))

                            HStack(spacing: 4) {
                                let earned = s.starsEarned ?? 0
                                ForEach(0..<(s.maxStars), id: \.self) { i in
                                    Image(systemName: i < earned ? "star.fill" : "star")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(i < earned ? Color.yellow : Color.white.opacity(0.2))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: startMission) {
                Text("START MISSION 🚀")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(startEnabled ? themePalette.accent : Color.gray)
                    .cornerRadius(18)
            }
            .disabled(!startEnabled)

            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.6), lineWidth: 2))
        }
    }

    private var startEnabled: Bool {
        if let sub = selectedSublevel, let _ = selectedMode {
            return sub.unlocked ?? true
        }
        return false
    }

    private func circleFill(for sublevel: Sublevel) -> LinearGradient {
        let unlocked = sublevel.unlocked ?? true
        let colors = unlocked ? themePalette.badgeGradient : [Color.gray.opacity(0.4), Color.black.opacity(0.4)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func startMission() {
        guard let sub = selectedSublevel, let mode = selectedMode else { return }
        onSelect(sub, mode)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Hero image helpers
private extension SublevelListView {
    private var heroAssetName: String? {
        themePalette.heroImageName == "heroDefault" ? nil : themePalette.heroImageName
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
    private var heroBackdropImage: some View {
        if let asset = heroAssetName, UIImage(named: asset) != nil {
            Image(asset)
                .resizable()
                .scaledToFit()
        } else if let url = heroRemoteURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.2))
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
}

// Simple toggle button used to pick play mode
struct ModeToggleButton: View {
    let label: String
    let emoji: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji).font(.largeTitle)
                Text(label)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .padding(12)
            .frame(width: 140, height: 90)
            .background(isSelected ? accent : Color.white.opacity(0.9))
            .cornerRadius(16)
            .shadow(radius: isSelected ? 8 : 2)
        }
    }
}

private struct SublevelThemePalette {
    let heroImageName: String
    let backgroundGradient: [Color]
    let badgeGradient: [Color]
    let accent: Color

    init(level: Level) {
        switch level.theme {
        case "Batman":
            heroImageName = "heroBatman"
            backgroundGradient = [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)]
            badgeGradient = [Color.yellow.opacity(0.9), Color.orange]
            accent = Color.yellow
        case "Spider-Man":
            heroImageName = "heroSpiderman"
            backgroundGradient = [Color.red.opacity(0.8), Color.blue.opacity(0.9)]
            badgeGradient = [Color.red, Color.blue]
            accent = Color(red: 0.95, green: 0.2, blue: 0.2)
        case "My Neighbour Totoro":
            heroImageName = "heroTotoro"
            backgroundGradient = [Color.green.opacity(0.5), Color.blue.opacity(0.5)]
            badgeGradient = [Color.green, Color.teal]
            accent = Color.green
        case "Pokémon", "Pokemon":
            heroImageName = "heroPokemon"
            backgroundGradient = [Color.yellow.opacity(0.7), Color.blue.opacity(0.6)]
            badgeGradient = [Color.yellow, Color.orange]
            accent = Color.yellow
        case "Marvel-Heroes":
            heroImageName = "heroAvengers"
            backgroundGradient = [Color.purple.opacity(0.6), Color.blue.opacity(0.7)]
            badgeGradient = [Color.purple, Color.blue]
            accent = Color.purple
        case "HunterxHunter":
            heroImageName = "heroHXH"
            backgroundGradient = [Color(red: 0, green: 0.4, blue: 0.2), Color.black]
            badgeGradient = [Color.green, Color.red]
            accent = Color.green
        default:
            heroImageName = "heroDefault"
            backgroundGradient = [Color.blue.opacity(0.3), Color.purple.opacity(0.5)]
            badgeGradient = [Color.blue, Color.purple]
            accent = Color.blue
        }
    }
}
