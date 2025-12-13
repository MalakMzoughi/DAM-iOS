//
//  LevelScreen.swift
//  DAM-iOS
//
//  Layout aligned with Android LevelScreen
//

import SwiftUI
import AVFoundation
import Foundation
import UIKit
import WebKit
import Combine

struct LevelScreen: View {

    // --------------------------------------------------
    // ENVIRONMENT + STATE
    // --------------------------------------------------
    @EnvironmentObject private var userSession: UserSession
    @EnvironmentObject private var router: AppRouter
    
    @StateObject private var viewModel: LevelViewModel
    @StateObject private var pitchDetector = PitchDetector()
    @State private var soundGen = SoundGenerator()
    
    @State private var showIntro: Bool
    @State private var showSublevelSelection: Bool
    @State private var showPreview: Bool
    @State private var showSuccessDialog = false
    @State private var showFailDialog = false
    @State private var pianoMode: PianoMode = .appPiano
    @State private var microphonePermissionDenied = false
    @State private var currentSublevel: Sublevel?
    @State private var allSublevels: [Sublevel] = []
    @State private var currentSublevelIndex = 0
    @State private var pressedNote: String?
    
    let level: Level
    let sublevel: Sublevel
    private let showsIntroAndSublevelSelection: Bool

    private var isBatmanTheme: Bool {
        level.theme.lowercased().contains("batman")
    }

    private var isSpiderTheme: Bool {
        level.theme.lowercased().contains("spider")
    }

    private var previewFallbackResource: String? {
        if isBatmanTheme { return "batman-preview" }
        if isSpiderTheme { return "spiderman-preview" }
        return nil
    }

    private var previewAudioSourceURL: String? {
        if isSpiderTheme || isBatmanTheme {
            return nil
        }
        return level.previewAudioUrl ?? level.musicUrl
    }

    private var avatarImageURL: URL? {
        if let avatarURL = userSession.activeAvatar?.avatarImageUrl,
           let url = URL(string: avatarURL) {
            return url
        }
        return userSession.profile.photoUrl
    }

    init(level: Level, sublevel: Sublevel, pianoMode: PianoMode = .appPiano, showsIntroAndSublevelSelection: Bool = true) {
        self.level = level
        self.sublevel = sublevel
        self.showsIntroAndSublevelSelection = showsIntroAndSublevelSelection

        _pianoMode = State(initialValue: pianoMode)
        _viewModel = StateObject(wrappedValue: LevelViewModel(level: level, sublevel: sublevel))

        if showsIntroAndSublevelSelection {
            _showIntro = State(initialValue: true)
            _showSublevelSelection = State(initialValue: false)
            _showPreview = State(initialValue: false)
        } else {
            _showIntro = State(initialValue: false)
            _showSublevelSelection = State(initialValue: false)
            _showPreview = State(initialValue: true)
            _currentSublevel = State(initialValue: sublevel)
            _currentSublevelIndex = State(initialValue: max(0, sublevel.index - 1))
        }
    }
    
    // --------------------------------------------------
    // BODY
    // --------------------------------------------------
    var body: some View {
        ZStack {
            if showsIntroAndSublevelSelection {
                if showIntro {
                    LevelIntroDialogView(
                        level: level,
                        onChooseSublevel: {
                            withAnimation {
                                showIntro = false
                                showSublevelSelection = true
                            }
                        }
                    )
                    .zIndex(100)
                }
                
                if showSublevelSelection && !showIntro {
                    SublevelListView(
                        level: level,
                        levelId: level.id,
                        userId: userSession.isLoggedIn ? userSession.profile.id : nil,
                        preselectedMode: nil,
                        onSelect: { selectedSublevel, selectedMode in
                            withAnimation {
                                showSublevelSelection = false
                                currentSublevel = selectedSublevel
                                currentSublevelIndex = selectedSublevel.index - 1
                                pianoMode = selectedMode
                                
                                if selectedSublevel.index == 1 || selectedSublevel.index == allSublevels.count {
                                    showPreview = true
                                } else {
                                    showPreview = false
                                    startGameplay(with: selectedSublevel, mode: selectedMode)
                                }
                            }
                        }
                    )
                    .onAppear {
                        if allSublevels.isEmpty {
                            loadSublevels()
                        }
                    }
                    .zIndex(50)
                }
            }
            
            if showPreview && currentSublevel != nil {
                PreviewDialog(
                    audioUrl: previewAudioSourceURL,
                    fallbackResource: previewFallbackResource,
                    autoPlay: level.autoPlayPreview ?? true,
                    onDismiss: {
                        withAnimation {
                            showPreview = false
                            startGameplay(with: currentSublevel!, mode: pianoMode)
                        }
                    }
                )
                .zIndex(60)
            }
            
            if !showPreview && currentSublevel != nil {
                gameplayContent
                    .transition(.opacity)
            }
        }
        .onChange(of: viewModel.isLevelCompleted, perform: handleLevelCompletion)
        .onChange(of: viewModel.isFailed, perform: handleLevelFailure)
        .onChange(of: pitchDetector.detectionEvent, perform: handleDetectionEvent)
        .onAppear {
            loadSublevels()
            if !showsIntroAndSublevelSelection {
                if currentSublevel == nil {
                    currentSublevel = sublevel
                    currentSublevelIndex = max(0, sublevel.index - 1)
                }
            }
        }
        .onDisappear {
            if pianoMode == .realPiano {
                cleanupRealPianoAudio()
            } else {
                soundGen.stop()
            }
            showSuccessDialog = false
        }
        .alert("Level Failed!", isPresented: $showFailDialog) {
            Button("Retry") {
                resetLevel()
            }
            Button("Exit") {
                if pianoMode == .realPiano {
                    cleanupRealPianoAudio()
                } else {
                    soundGen.stop()
                }
                router.current = .home
            }
        } message: {
            Text("You've run out of lives. Try again!")
        }
        .alert("Microphone Access Required", isPresented: $microphonePermissionDenied) {
            Button("Cancel") {
                router.current = .home
            }
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please allow microphone access in Settings to use Real Piano mode.")
        }
    }
    
    // --------------------------------------------------
    // GAMEPLAY CONTENT
    // --------------------------------------------------
    private var gameplayContent: some View {
        ZStack {
            backgroundLayer
            gameplayUI
            if showSuccessDialog {
                LevelCompletedDialogView(stars: viewModel.starsEarned) {
                    showSuccessDialog = false
                    handleSublevelCompletion()
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
    
    // --------------------------------------------------
    // LOAD SUBLEVELS
    // --------------------------------------------------
    private func loadSublevels() {
        Task {
            let baseRepo = SublevelRepository()
            let progressRepo = SublevelProgressRepository()

            var fetched: [Sublevel]? = nil

            if userSession.isLoggedIn {
                fetched = await progressRepo.getUserSublevels(
                    userId: userSession.profile.id,
                    levelId: level.id
                )
            }

            if fetched == nil {
                fetched = await baseRepo.getSublevelsByLevel(level.id)
            }

            if let sublevels = fetched {
                await MainActor.run {
                    let sorted = sublevels.sorted { $0.index < $1.index }
                    self.allSublevels = sorted

                    if let active = self.currentSublevel,
                       let refreshed = sorted.first(where: { $0.id == active.id }) {
                        self.currentSublevel = refreshed
                    }
                }
            }
        }
    }
    
    // --------------------------------------------------
    // START GAMEPLAY
    // --------------------------------------------------
    private func startGameplay(with sublevel: Sublevel, mode: PianoMode) {
        Task { @MainActor in
            viewModel.loadSublevel(sublevel)
            self.pianoMode = mode
            self.currentSublevel = sublevel

            if mode == .realPiano {
                startMicrophoneListening()
            } else {
                soundGen.stop()
            }
        }
    }
    
    // --------------------------------------------------
    // HANDLE SUBLEVEL COMPLETION
    // --------------------------------------------------
    private func handleSublevelCompletion() {
        if currentSublevelIndex < allSublevels.count - 1 {
            let nextSublevel = allSublevels[currentSublevelIndex + 1]
            currentSublevelIndex += 1
            currentSublevel = nextSublevel
            
            if nextSublevel.index == allSublevels.count {
                showPreview = true
                showSuccessDialog = false
            } else {
                showSuccessDialog = false
                startGameplay(with: nextSublevel, mode: pianoMode)
            }
        } else {
            if pianoMode == .realPiano {
                cleanupRealPianoAudio()
            } else {
                soundGen.stop()
            }
            router.current = .home
        }
    }
    
    // --------------------------------------------------
    // MICROPHONE LISTENING
    // --------------------------------------------------
    private func startMicrophoneListening() {
        pitchDetector.requestMicrophonePermission { granted in
            if granted {
                pitchDetector.startListening()
            } else {
                microphonePermissionDenied = true
            }
        }
    }
    
    // --------------------------------------------------
    // RESET LOGIC
    // --------------------------------------------------
    private var animatedGifSource: GIFPlayerView.Source? {
        if let urlString = level.backgroundUrl,
           urlString.lowercased().hasSuffix(".gif"),
           let url = URL(string: urlString) {
            return .remote(url)
        }

        if let data = localGifData {
            return .data(data)
        }

        return nil
    }

    private var localGifData: Data? {
        if let assetKey = level.backgroundAssetKey,
           let assetData = GifLoader.data(named: assetKey) {
            return assetData
        }

        switch level.order {
        case 3:
            return GifLoader.totoroBackgroundData
        case 4:
            return GifLoader.pokemonBackgroundData
        case 5:
            return GifLoader.ironmanBackgroundData
        case 6:
            return GifLoader.hunterBackgroundData
        default:
            break
        }

        if isBatmanTheme {
            return GifLoader.batmanBackgroundData
        }

        if isSpiderTheme {
            return GifLoader.spidermanBackgroundData
        }

        return nil
    }

    private func resetLevel() {
        showFailDialog = false
        showSuccessDialog = false
        showPreview = false
        if let activeSublevel = currentSublevel {
            startGameplay(with: activeSublevel, mode: pianoMode)
        } else {
            viewModel.reset()
        }
    }
    
    // --------------------------------------------------
    // HERO IMAGE PICKER
    // --------------------------------------------------
    private func heroImageName(for theme: String) -> String {
        switch theme.lowercased() {
        case "batman":
            return "heroBatman"
        case "spider-man", "spiderman":
            return "heroSpiderman"
        case "superman":
            return "heroBatman"
        case "captain america", "captainamerica":
            return "heroBatman"
        case "magical girl", "magicalgirl":
            return "heroSpiderman"
        case "pirate":
            return "heroBatman"
        case "totoro", "my neighbor totoro":
            return "heroSpiderman"
        case "pokemon", "pokémon":
            return "heroSpiderman"
        case "marvel heroes", "marvel-heroes":
            return "heroSpiderman"
        case "hunter x hunter", "hunterxhunter", "hxh":
            return "heroSpiderman"
        default:
            return "heroBatman"
        }
    }

    private var shouldUseAvatarForHeroCard: Bool {
        isSpiderTheme || [3, 4, 5, 6].contains(level.order)
    }

    private var shouldShowHeroBubble: Bool {
        isBatmanTheme || isSpiderTheme
    }

    private var shouldForceMediumSpeed: Bool {
        isSpiderTheme && (currentSublevel?.index == 5)
    }
    
    // --------------------------------------------------
    // GAMEPLAY UI - ANDROID-ALIGNED LAYOUT
    // --------------------------------------------------
    private var gameplayUI: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                let bottomSectionHeight: CGFloat = pianoMode == .appPiano ? 230 : 170
                let topBarHeight: CGFloat = 76
                let gameAreaHeight = max(geometry.size.height - topBarHeight - bottomSectionHeight, 240)

                // TOP BAR
                HStack(spacing: 12) {
                    exitButton

                    progressBadge(progress: viewModel.progress, score: viewModel.score)
                        .frame(width: 140, height: 60)

                    starProgressBar(progress: viewModel.progress, stars: starsForProgress(viewModel.progress))
                        .frame(height: 42)

                    livesStrip
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .frame(height: topBarHeight)

                // MAIN GAME AREA
                ZStack {
                    verticalLanesView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 16)

                    HStack(alignment: .top) {
                        heroCharacterStack
                        Spacer()
                        bossCardView
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                .frame(height: gameAreaHeight)

                // BOTTOM CONTROLS
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        progressTile

                        Spacer()

                        HStack(spacing: 10) {
                            modeButton(icon: "music.note", label: "APP PIANO", isSelected: pianoMode == .appPiano, color: .blue) {
                                pianoMode = .appPiano
                                cleanupRealPianoAudio()
                            }

                            modeButton(icon: "pianokeys", label: "MY PIANO", isSelected: pianoMode == .realPiano, color: .green) {
                                pianoMode = .realPiano
                                soundGen.stop()
                                startMicrophoneListening()
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 64)

                    if pianoMode == .appPiano {
                        pianoKeyboardView
                            .frame(height: 130)
                            .padding(.horizontal, 6)
                            .transition(.opacity)
                    } else {
                        microphoneIndicatorView
                            .frame(height: 110)
                            .padding(.horizontal, 6)
                            .transition(.opacity)
                    }
                }
                .frame(height: bottomSectionHeight)
                .padding(.bottom, 6)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
            }
        }
    }

    // --------------------------------------------------
    // TOP BAR ELEMENTS
    // --------------------------------------------------
    private var exitButton: some View {
        Button(action: exitLevel) {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.12))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                )
        }
    }

    private func progressBadge(progress: Double, score: Int) -> some View {
        let clamped = max(0, min(1, progress))
        return VStack(alignment: .leading, spacing: 4) {
            Text("Progress")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            Text("\(Int(clamped * 100))%")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.white)
            Text("Score \(score)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
    }

    private func starProgressBar(progress: Double, stars: Int) -> some View {
        let clamped = max(0, min(1, progress))
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.08))
                    )

                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.white.opacity(0.15)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * clamped)
                    .animation(.easeInOut(duration: 0.35), value: clamped)

                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { index in
                        let filled = index < stars
                        Image(systemName: filled ? "star.fill" : "star")
                            .foregroundColor(filled ? Color.white : Color.white.opacity(0.4))
                            .font(.system(size: 16, weight: .bold))
                            .shadow(color: filled ? Color.white.opacity(0.4) : Color.clear, radius: 6)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var livesStrip: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: "heart.fill")
                    .foregroundColor(index < viewModel.lives ? .red : Color.white.opacity(0.35))
                    .font(.system(size: 18))
                    .padding(6)
                    .background(Color.black.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }

    private func exitLevel() {
        if pianoMode == .realPiano {
            cleanupRealPianoAudio()
        } else {
            soundGen.stop()
        }
        router.current = .home
    }

    // --------------------------------------------------
    // GAME AREA ELEMENTS
    // --------------------------------------------------
    private var heroCardView: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                heroCardImageContent()
                    .frame(width: 110, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    )

                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Image(systemName: "checkmark")
                            .foregroundColor(.black)
                            .font(.system(size: 12, weight: .bold))
                    )
                    .offset(x: 6, y: -6)
            }

            Text("HERO")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.55))
                )
        }
        .frame(width: 110)
    }

    @ViewBuilder
    private func heroCardImageContent() -> some View {
        if shouldUseAvatarForHeroCard, let url = avatarImageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Image(heroImageName(for: level.theme))
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                @unknown default:
                    Image(heroImageName(for: level.theme))
                        .resizable()
                        .scaledToFill()
                }
            }
        } else {
            Image(heroImageName(for: level.theme))
                .resizable()
                .scaledToFill()
        }
    }

    private var avatarCardView: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 150, height: 210)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    )

                avatarImageContent()
                    .frame(width: 150, height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Text("YOUR AVATAR")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.55))
                )
        }
        .frame(width: 160)
    }

    private var heroCharacterStack: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if isBatmanTheme {
                    avatarCardView
                } else {
                    heroCardView
                }
            }

            if shouldShowHeroBubble, let message = viewModel.heroMessage {
                HeroSpeechBubble(message: message, isPositive: viewModel.heroMessageIsPositive)
                    .offset(y: -24)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: viewModel.heroMessage)
    }

    @ViewBuilder
    private func avatarImageContent() -> some View {
        if let url = avatarImageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Image(heroImageName(for: level.theme))
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                @unknown default:
                    Color.clear
                }
            }
        } else {
            Image(heroImageName(for: level.theme))
                .resizable()
                .scaledToFill()
        }
    }

    private var bossCardView: some View {
        VStack(spacing: 6) {
            if let url = URL.backendAsset(from: level.bossUrl) {
                AsyncImage(url: url) { img in
                    img.resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.black.opacity(0.12)
                }
                .frame(width: 110, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                )
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.12))
                    .frame(width: 110, height: 160)
                    .overlay(
                        Image(systemName: "questionmark")
                            .foregroundColor(.white.opacity(0.7))
                    )
            }

            Text("BOSS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.55))
                )
        }
        .frame(width: 110)
    }

    private var progressTile: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                )

            VStack(alignment: .leading, spacing: 0) {
                Text("Progress")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(Int(viewModel.progress * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.08))
        )
    }
    
    // --------------------------------------------------
    // FALLING NOTES BOARD
    // --------------------------------------------------
    private func verticalLanesView() -> some View {
        FallingNotesBoard(
            notes: currentSublevel?.notes ?? sublevel.notes,
            durations: currentSublevel?.noteDurations ?? sublevel.noteDurations,
            currentIndex: viewModel.currentIndex,
            isActive: currentSublevel != nil && !showPreview,
            forceMediumSpeed: shouldForceMediumSpeed,
            tempoMultiplier: shouldForceMediumSpeed ? 1.35 : 1.0
        )
        .id(viewModel.resetStamp)
    }
    
    // --------------------------------------------------
    // MODE BUTTON - COMPACT
    // --------------------------------------------------
    private func modeButton(icon: String, label: String, isSelected: Bool, color _: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(isSelected ? 0.35 : 0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                }
                
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    // --------------------------------------------------
    // MICROPHONE INDICATOR VIEW - FOR REAL PIANO MODE
    // --------------------------------------------------
    private var microphoneIndicatorView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Microphone icon with pulse animation
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("🎹 Play on Your Piano")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Listening for notes...")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.5), lineWidth: 2)
                    )
            )
        }
    }
    
    // --------------------------------------------------
    // PIANO KEYBOARD VIEW - ANDROID PARITY
    // --------------------------------------------------
    private var pianoKeyboardView: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 8
            let whiteKeyCount = PianoKeyboardLayout.whiteKeys.count
            let keyWidth = max(0, (geo.size.width - spacing * CGFloat(whiteKeyCount - 1)) / CGFloat(whiteKeyCount))
            let keyHeight = geo.size.height
            let blackHeight = keyHeight * 0.58
            let blackWidth = keyWidth * 0.45
            let blackOffsetX = keyWidth * 0.36

            ZStack(alignment: .topLeading) {
                HStack(spacing: spacing) {
                    ForEach(PianoKeyboardLayout.whiteKeys) { descriptor in
                        whiteKeyButton(descriptor, size: CGSize(width: keyWidth, height: keyHeight))
                            .frame(width: keyWidth, height: keyHeight)
                            .zIndex(1)
                    }
                }
                .frame(height: keyHeight)

                HStack(spacing: spacing) {
                    ForEach(PianoKeyboardLayout.whiteKeys) { descriptor in
                        ZStack(alignment: .topLeading) {
                            if let black = descriptor.blackKey {
                                blackKeyButton(black, size: CGSize(width: blackWidth, height: blackHeight))
                                    .offset(x: blackOffsetX)
                                    .zIndex(2)
                            }
                        }
                        .frame(width: keyWidth, height: blackHeight, alignment: .topLeading)
                    }
                }
                .padding(.top, keyHeight * 0.01)
            }
        }
        .frame(height: 150)
        .padding(.horizontal, 6)
    }

    private func whiteKeyButton(_ descriptor: PianoKeyboardLayout.WhiteKeyDescriptor, size: CGSize) -> some View {
        let isPressed = pressedNote == descriptor.note.inputValue
        return Button {
            triggerNote(descriptor.note)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: isPressed ?
                            [descriptor.color.opacity(0.8), descriptor.color.opacity(0.6)] :
                            [descriptor.color, descriptor.color.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isPressed ? Color.white.opacity(0.8) : Color.black.opacity(0.25), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 3)

                VStack(spacing: 2) {
                    Spacer()
                    Text(descriptor.note.displayValue)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.black.opacity(0.75))
                    Text(descriptor.note.letterValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.black.opacity(0.5))
                        .padding(.bottom, 10)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .buttonStyle(.plain)
    }

    private func blackKeyButton(_ descriptor: PianoKeyboardLayout.BlackKeyDescriptor, size: CGSize) -> some View {
        let isPressed = pressedNote == descriptor.note.inputValue
        return Button {
            triggerNote(descriptor.note)
        } label: {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: isPressed ?
                        [Color(white: 0.2), Color(white: 0.35)] :
                        [Color(white: 0.05), Color(white: 0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isPressed ? Color.white.opacity(0.7) : Color.black.opacity(0.6), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.45), radius: 3, x: 0, y: 3)
                .overlay(
                    Text(descriptor.note.displayValue)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 6),
                    alignment: .bottom
                )
                .frame(width: size.width, height: size.height)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
    
    // --------------------------------------------------
    // HELPER: HANDLE KEY PRESS
    // --------------------------------------------------
    private func triggerNote(_ note: PianoKeyboardLayout.PianoNoteDescriptor) {
        pressedNote = note.inputValue
        handleKeyPress(note.inputValue)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if pressedNote == note.inputValue {
                pressedNote = nil
            }
        }
    }

    private func handleKeyPress(_ note: String) {
        if pianoMode == .appPiano {
            soundGen.playNote(noteName: note)
        }
        viewModel.onNotePlayed(note)
    }
    
    
    private func starsForProgress(_ progress: Double) -> Int {
        if progress >= 0.9 { return 3 }
        if progress >= 0.7 { return 2 }
        if progress >= 0.4 { return 1 }
        return 0
    }

    // --------------------------------------------------
    // BACKGROUND
    // --------------------------------------------------
    private var backgroundLayer: some View {
        ZStack {
            if let gifSource = animatedGifSource {
                GIFPlayerView(source: gifSource)
                    .ignoresSafeArea()
            } else if let bg = level.backgroundUrl, let url = URL(string: bg) {
                AsyncImage(url: url) { img in
                    img.resizable()
                } placeholder: { Color.black }
                .scaledToFill()
                .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: isBatmanTheme ?
                        [
                            Color.black.opacity(0.03),
                            Color(red: 0.6, green: 0.0, blue: 0.0).opacity(0.55)
                        ] :
                        [
                            Color.black.opacity(0.06),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
        }
    }

    // --------------------------------------------------
    // ON CHANGE HANDLERS
    // --------------------------------------------------
    private func handleLevelCompletion(_ completed: Bool) {
        guard completed else { return }
        Task {
            if pianoMode == .realPiano {
                cleanupRealPianoAudio()
            } else {
                soundGen.stop()
            }

            var updatedSublevels: [Sublevel]? = nil

            if userSession.isLoggedIn {
                updatedSublevels = await viewModel.saveProgress(userId: userSession.profile.id)
            } else {
                print("LevelScreen: guest mode – not saving progress")
            }

            await MainActor.run {
                if let updated = updatedSublevels {
                    self.allSublevels = updated
                    if let current = self.currentSublevel,
                       let refreshed = updated.first(where: { $0.id == current.id }) {
                        self.currentSublevel = refreshed
                    }
                }
                showSuccessDialog = true
            }
        }
    }

    private func handleLevelFailure(_ failed: Bool) {
        guard failed else { return }
        Task { @MainActor in
            if pianoMode == .realPiano {
                cleanupRealPianoAudio()
            } else {
                soundGen.stop()
            }
            showFailDialog = true
        }
    }

    private func handleDetectionEvent(_ event: PitchDetectionEvent?) {
        guard pianoMode == .realPiano, let event, let expected = viewModel.nextNote else { return }
        let normalizedDetected = normalize(event.note)
        let normalizedExpected = normalize(expected)
        let isMatch = normalizedDetected == normalizedExpected

        if isMatch {
            print("✅ Note matched: \(event.note.uppercased()) for expected \(expected.uppercased())")
        } else {
            print("❌ Detected \(event.note.uppercased()) – expected \(expected.uppercased())")
        }

        viewModel.onNotePlayed(event.note)
    }
    
    // --------------------------------------------------
    // HELPERS
    // --------------------------------------------------
    private func normalize(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "è", with: "e")
            .replacingOccurrences(of: "ê", with: "e")
            .replacingOccurrences(of: "à", with: "a")
            .replacingOccurrences(of: "ù", with: "u")
            .replacingOccurrences(of: "ô", with: "o")
    }
    
    private func cleanupRealPianoAudio() {
        pitchDetector.stopListening()
        soundGen.stop()
        deactivateAudioSession()
    }
    
    private func deactivateAudioSession() {
        Task { @MainActor in
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
            } catch {
                print("⚠️ LevelScreen: Failed to deactivate audio session: \(error)")
            }
        }
    }
}

// --------------------------------------------------
// HERO SPEECH BUBBLE (Batman & Spider levels)
// --------------------------------------------------
private struct HeroSpeechBubble: View {
    let message: String
    let isPositive: Bool

    private var colors: (background: Color, border: Color, text: Color) {
        if isPositive {
            return (
                Color(red: 0.18, green: 0.45, blue: 0.95).opacity(0.25),
                Color(red: 0.45, green: 0.78, blue: 1.0).opacity(0.8),
                Color.white
            )
        }
        return (
            Color(red: 0.65, green: 0.09, blue: 0.13).opacity(0.25),
            Color(red: 1.0, green: 0.43, blue: 0.43).opacity(0.8),
            Color.white
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            BubblePointer()
                .fill(colors.background)
                .frame(width: 16, height: 18)
                .overlay(
                    BubblePointer()
                        .stroke(colors.border, lineWidth: 1)
                        .frame(width: 16, height: 18)
                )
                .padding(.trailing, -4)

            Text(message)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(colors.text)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colors.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(colors.border, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                )
        }
    }
}

private struct BubblePointer: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

// MARK: - Falling Notes Support
private struct FallingNoteSprite: Identifiable, Equatable {
    let id: Int
    let note: String
    var offsetY: CGFloat
    let lane: Int
    let lengthFactor: CGFloat
}

private struct FallingNotesBoard: View {
    let notes: [String]
    let durations: [String]?
    let currentIndex: Int
    let isActive: Bool
    let forceMediumSpeed: Bool
    let tempoMultiplier: CGFloat

    @State private var sprites: [FallingNoteSprite] = []
    @State private var nextSpawnIndex: Int = 0
    @State private var lastIndex: Int = 0
    @State private var spawnOffsets: [CGFloat] = []

    private let laneCount = 7
    // Faster global fall speed (was 0.0038, then 0.0062)
    private let baseSpeed: CGFloat = 0.0095
    private let spawnSpacingBase: CGFloat = 0.12
    private let freezeThreshold: CGFloat = 0.92
    private let previewWindow = 5
    private let maxVisibleOffset: CGFloat = 1.2
    private let timer = Timer.publish(every: 1.0 / 60.0, tolerance: 0.003, on: .main, in: .common).autoconnect()

    private var effectiveBaseSpeed: CGFloat { baseSpeed * tempoMultiplier }
    private var effectiveSpacing: CGFloat { spawnSpacingBase / max(0.6, tempoMultiplier) }

    var body: some View {
        let durationSignature = (try? JSONEncoder().encode(durations ?? [])) ?? Data()
        return GeometryReader { geo in
            let laneWidth = geo.size.width / CGFloat(laneCount)
            let containerHeight = geo.size.height
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    drawGrid(context: &context, size: size)
                }

                if notes.isEmpty {
                    Text("No notes available")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(sprites) { sprite in
                        noteShape(
                            for: sprite,
                            laneWidth: laneWidth,
                            containerHeight: containerHeight
                        )
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .animation(.linear(duration: 0.05), value: sprites)
        }
        .onAppear { resetState(startIndex: currentIndex) }
        .onChange(of: notes) { _ in resetState(startIndex: currentIndex) }
        .onChange(of: durationSignature) { _ in resetState(startIndex: currentIndex) }
        .onChange(of: currentIndex) { handleIndexChange($0) }
        .onReceive(timer) { _ in
            guard isActive else { return }
            updateSprites()
        }
    }

    private func resetState(startIndex: Int) {
        let alignmentIndex = min(max(0, startIndex), max(notes.count - 1, 0))
        spawnOffsets = computeSpawnOffsets(alignedTo: alignmentIndex)
        sprites = []
        nextSpawnIndex = min(max(0, startIndex), notes.count)
        lastIndex = startIndex
    }

    private func handleIndexChange(_ index: Int) {
        if index < lastIndex {
            resetState(startIndex: index)
            return
        }

        sprites = sprites.filter { $0.id >= index }
        if nextSpawnIndex < index {
            nextSpawnIndex = index
        }
        lastIndex = index
    }

    private func updateSprites() {
        guard !notes.isEmpty else { return }

        var updated = sprites.filter { $0.offsetY <= maxVisibleOffset }
        for idx in updated.indices {
            guard updated[idx].id >= currentIndex else { continue }
            // Speed should be independent of note length; length only affects visual size/spacing.
            let speed = effectiveBaseSpeed
            var nextOffset = updated[idx].offsetY + speed
            // Freeze all notes at the hit zone, waiting for the current note to be hit
            if nextOffset >= freezeThreshold {
                nextOffset = min(nextOffset, freezeThreshold)
            }
            updated[idx].offsetY = nextOffset
        }
        sprites = updated
        spawnIfNeeded()
    }

    private func spawnIfNeeded() {
        guard !notes.isEmpty else { return }

        while nextSpawnIndex < notes.count &&
                nextSpawnIndex < currentIndex + previewWindow &&
                !sprites.contains(where: { $0.id == nextSpawnIndex }) {

            let rawNote = notes[nextSpawnIndex]
            let laneIndex = lane(for: rawNote)
            let adjustedFactor = clampedLengthFactor(for: nextSpawnIndex)
            let spawnOffset = spawnOffset(for: nextSpawnIndex, currentSprites: sprites, lengthFactor: adjustedFactor)

            sprites.append(
                FallingNoteSprite(
                    id: nextSpawnIndex,
                    note: rawNote,
                    offsetY: spawnOffset,
                    lane: laneIndex,
                    lengthFactor: adjustedFactor
                )
            )

            nextSpawnIndex += 1
        }
    }

    private func computeSpawnOffsets(alignedTo index: Int) -> [CGFloat] {
        guard !notes.isEmpty else { return [] }

        var offsets: [CGFloat] = []
        var cumulative: CGFloat = 0

        for idx in notes.indices {
            offsets.append(-0.35 - cumulative)
            cumulative += effectiveSpacing * spacingMultiplier(for: idx)
        }

        if notes.indices.contains(index) {
            let shift = offsets[index] + 0.35
            if shift != 0 {
                for idx in index..<offsets.count {
                    offsets[idx] -= shift
                }
            }
        }

        return offsets
    }

    private func spacingMultiplier(for index: Int) -> CGFloat {
        return 1.0
    }

    private func clampedLengthFactor(for index: Int) -> CGFloat {
        if forceMediumSpeed {
            return 1.0
        }
        let raw = lengthFactor(for: index)
        return max(0.7, min(raw, 2.4))
    }

    private func spawnOffset(for index: Int, currentSprites: [FallingNoteSprite], lengthFactor: CGFloat) -> CGFloat {
        if spawnOffsets.indices.contains(index) {
            return spawnOffsets[index]
        }

        let spacing = effectiveSpacing
        let highestOffset = currentSprites.map(\.offsetY).min() ?? -0.35
        return min(highestOffset - spacing, -0.35)
    }

    private func drawGrid(context: inout GraphicsContext, size: CGSize) {
        let laneWidth = size.width / CGFloat(laneCount)

        for lane in 0..<laneCount {
            let rect = CGRect(x: CGFloat(lane) * laneWidth, y: 0, width: laneWidth, height: size.height)
            context.fill(Path(rect), with: .color(laneColor(for: lane).opacity(0.18)))

            if lane > 0 {
                let divider = CGRect(x: rect.minX, y: 0, width: 0.8, height: size.height)
                context.fill(Path(divider), with: .color(Color.white.opacity(0.06)))
            }
        }

        let busyLanes = Set(sprites.filter { $0.offsetY > -0.15 && $0.offsetY < 1.05 }.map(\.lane))
        let focusedLane = sprites.first(where: { $0.id == currentIndex })?.lane

        for lane in busyLanes {
            let rect = CGRect(x: CGFloat(lane) * laneWidth, y: 0, width: laneWidth, height: size.height)
            let opacity = lane == focusedLane ? 0.24 : 0.12
            context.fill(Path(rect), with: .color(Color.white.opacity(opacity)))
        }

        let hitZoneY = size.height * freezeThreshold
        let lineRect = CGRect(x: 0, y: hitZoneY - 2, width: size.width, height: 4)
        context.fill(Path(lineRect), with: .color(Color.white))

        let glowRect = CGRect(x: 0, y: hitZoneY - 48, width: size.width, height: 48)
        context.fill(
            Path(glowRect),
            with: .linearGradient(
                Gradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.0)]),
                startPoint: CGPoint(x: 0, y: hitZoneY - 48),
                endPoint: CGPoint(x: 0, y: hitZoneY)
            )
        )
    }

    private func noteShape(for sprite: FallingNoteSprite, laneWidth: CGFloat, containerHeight: CGFloat) -> some View {
        let xPos = laneWidth * (CGFloat(sprite.lane) + 0.5)
        let yPos = containerHeight * sprite.offsetY
        let noteHeight = max(56, (70 * sprite.lengthFactor) + 36)

        return RoundedRectangle(cornerRadius: 12)
            .fill(noteGradient(for: sprite))
            .frame(width: laneWidth * 0.78, height: noteHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(sprite.id == currentIndex ? Color.yellow : Color.white.opacity(0.35), lineWidth: 2)
            )
            .overlay(
                Text(sprite.note.uppercased())
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(.white)
            )
            .position(x: xPos, y: yPos)
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 8)
    }

    private func noteGradient(for sprite: FallingNoteSprite) -> LinearGradient {
        if sprite.id == currentIndex {
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.87, blue: 0.36),
                    Color(red: 1.0, green: 0.64, blue: 0.29)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(red: 0.0, green: 0.85, blue: 1.0),
                Color(red: 0.39, green: 0.48, blue: 0.91)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func laneColor(for index: Int) -> Color {
        let shade = 0.85 - (Double(index % 3) * 0.05)
        return Color(white: shade)
    }

    private func lane(for note: String) -> Int {
        let normalized = normalize(note)

        switch normalized {
        case "do", "c", "c#", "db": return 0
        case "re", "d", "ré", "d#", "eb": return 1
        case "mi", "e", "fb": return 2
        case "fa", "f", "e#": return 3
        case "sol", "g", "g#", "ab": return 4
        case "la", "a", "a#", "bb": return 5
        case "si", "b", "cb": return 6
        default: return 0
        }
    }

    private func lengthFactor(for index: Int) -> CGFloat {
        if forceMediumSpeed {
            return 1.0
        }
        if let durations,
           durations.indices.contains(index) {
            let token = durations[index].lowercased()
            switch token {
            case "long": return 1.8
            case "short": return 0.8
            case "medium": return 1.2
            default:
                if let value = Double(token) {
                    return max(0.5, min(value, 2.5))
                }
            }
        }

        guard notes.indices.contains(index) else { return 1 }
        let token = normalize(notes[index])
        if token.contains("hold") { return 1.6 }
        if token.contains("rest") { return 0.7 }
        return 1
    }

    private func normalize(_ raw: String) -> String {
        var value = raw
            .lowercased()
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "è", with: "e")
            .replacingOccurrences(of: "ê", with: "e")
            .replacingOccurrences(of: "à", with: "a")
            .replacingOccurrences(of: "ù", with: "u")
            .replacingOccurrences(of: "ô", with: "o")
            .replacingOccurrences(of: "♭", with: "b")
            .replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "sharp", with: "#")
            .replacingOccurrences(of: "flat", with: "b")
            .replacingOccurrences(of: " ", with: "")

        var accidental = ""
        if value.hasSuffix("#") {
            accidental = "#"
            value = String(value.dropLast())
        } else if value.hasSuffix("b") && value.count > 1 {
            accidental = "b"
            value = String(value.dropLast())
        }

        let mapping: [String: String] = [
            "do": "c", "c": "c",
            "re": "d", "d": "d",
            "mi": "e", "e": "e",
            "fa": "f", "f": "f",
            "sol": "g", "g": "g",
            "la": "a", "a": "a",
            "si": "b", "ti": "b", "b": "b"
        ]

        let base = mapping[value] ?? value
        return base + accidental
    }
}

// MARK: - Level Intro Dialog
struct LevelIntroDialog: View {
    let heroImageName: String
    let storyText: String
    var onFinished: () -> Void
    
    @State private var typedText = ""
    @State private var showButton = false
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.525, green: 0.71, blue: 0.945).opacity(0.5),
                    Color(red: 0.173, green: 0.243, blue: 0.314).opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("MISSION BRIEFING")
                            .font(.system(size: 22, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(Color(red: 0.173, green: 0.243, blue: 0.314))
                        
                        Divider()
                            .background(Color(red: 0.525, green: 0.71, blue: 0.945).opacity(0.3))
                    }
                    
                    HStack(spacing: 20) {
                        VStack(spacing: 0) {
                            ZStack {
                                Image(heroImageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 180)
                                    .cornerRadius(16)
                                    .shadow(radius: 12)
                            }
                        }
                        .frame(width: 140, height: 180)
                        
                        VStack(spacing: 12) {
                            ScrollView {
                                Text(typedText)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color(red: 0.173, green: 0.243, blue: 0.314))
                                    .lineSpacing(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            if showButton {
                                Button(action: onFinished) {
                                    HStack(spacing: 6) {
                                        Text("START")
                                            .font(.system(size: 16, weight: .bold))
                                            .tracking(1)
                                        Text("🚀")
                                            .font(.system(size: 16))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.525, green: 0.71, blue: 0.945),
                                                Color(red: 0.506, green: 0.784, blue: 0.518)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                                }
                                .transition(.opacity)
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    
                    HStack(spacing: 8) {
                        Text("💡")
                        Text("Listen carefully and play the correct notes to win!")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(red: 0.525, green: 0.71, blue: 0.945))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.953, green: 0.976, blue: 1.0).opacity(0.8))
                    .cornerRadius(12)
                }
                .padding(24)
                .background(Color.white.opacity(0.95))
                .cornerRadius(28)
                .shadow(radius: 20)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 24)
                .scaleEffect(isVisible ? 1 : 0.8)
                .opacity(isVisible ? 1 : 0)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                typedText = ""
                for (index, char) in storyText.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.035) {
                        typedText.append(char)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(storyText.count) * 0.035 + 0.5) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showButton = true
                    }
                }
            }
        }
    }
}

// MARK: - Preview Dialog
struct PreviewDialog: View {
    let audioUrl: String?
    let fallbackResource: String?
    let autoPlay: Bool
    var onDismiss: () -> Void
    
    @State private var isPlaying = false
    @State private var player: AVPlayer?
    @State private var statusObserver: NSKeyValueObservation?
    @State private var showLoadingSpinner = false
    @State private var errorMessage: String?
    @State private var hasAutoPlayed = false
    @State private var playbackEndObserver: NSObjectProtocol?
    @State private var playbackFailureObserver: NSObjectProtocol?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "music.note")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.525, green: 0.71, blue: 0.945),
                                Color(red: 0.506, green: 0.784, blue: 0.518)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 12) {
                    Text("Listen to the Theme")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Preview the melody you need to play")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.red.opacity(0.3))
                        .cornerRadius(12)
                } else if showLoadingSpinner {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.5)
                } else {
                    Button(action: togglePlayback) {
                        HStack(spacing: 12) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 32))
                            Text(isPlaying ? "Pause Preview" : "Play Theme")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.525, green: 0.71, blue: 0.945),
                                    Color(red: 0.506, green: 0.784, blue: 0.518)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                    }
                }
                
                Button(action: onDismiss) {
                    Text("Ready! Let's Play")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.2))
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        )
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.2))
                    .shadow(radius: 20)
            )
            .padding(24)
        }
        .onAppear {
            if autoPlay && !hasAutoPlayed {
                hasAutoPlayed = true
                startPlayback()
            }
        }
        .onDisappear {
            cleanupPlayer()
        }
    }
    
    private func togglePlayback() {
        if showLoadingSpinner {
            return
        }

        if isPlaying {
            player?.pause()
            isPlaying = false
            return
        }

        if let player, player.currentItem?.status == .readyToPlay {
            player.seek(to: .zero)
            player.play()
            isPlaying = true
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        guard !showLoadingSpinner else { return }
        cleanupPlayer()

        guard let audioURL = resolvedAudioURL() else {
            errorMessage = "Preview audio not available"
            return
        }

        showLoadingSpinner = true
        errorMessage = nil

        let playerItem = AVPlayerItem(url: audioURL)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player

        playbackFailureObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: playerItem, queue: .main) { _ in
            isPlaying = false
            showLoadingSpinner = false
            errorMessage = "Unable to play preview."
        }

        playbackEndObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { _ in
            isPlaying = false
        }

        statusObserver = playerItem.observe(\.status, options: [.new]) { item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    showLoadingSpinner = false
                    isPlaying = true
                    player.play()
                case .failed:
                    showLoadingSpinner = false
                    isPlaying = false
                    errorMessage = playerItem.error?.localizedDescription ?? "Preview failed to load."
                default:
                    break
                }
            }
        }
    }

    private func cleanupPlayer() {
        player?.pause()
        player = nil
        statusObserver = nil

        if let playbackEndObserver {
            NotificationCenter.default.removeObserver(playbackEndObserver)
        }
        if let playbackFailureObserver {
            NotificationCenter.default.removeObserver(playbackFailureObserver)
        }

        playbackEndObserver = nil
        playbackFailureObserver = nil
        showLoadingSpinner = false
        isPlaying = false
    }

    private func resolvedAudioURL() -> URL? {
        if let urlString = audioUrl, let remoteURL = URL(string: urlString) {
            return remoteURL
        }

        if let fallback = fallbackResource,
           let bundledURL = Bundle.main.url(forResource: fallback, withExtension: "mp3") {
            return bundledURL
        }

        return nil
    }
}

// MARK: - GIF Utilities
private struct GIFPlayerView: UIViewRepresentable {
    enum Source {
        case data(Data)
        case remote(URL)
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
                let htmlString: String

                switch source {
                case .data(let data):
                        let base64 = data.base64EncodedString()
                        htmlString = GIFPlayerView.htmlWrapper(for: "data:image/gif;base64,\(base64)")
                case .remote(let url):
                        htmlString = GIFPlayerView.htmlWrapper(for: url.absoluteString)
                }

                webView.loadHTMLString(htmlString, baseURL: nil)
    }

        private static func htmlWrapper(for source: String) -> String {
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
                        <img src='\(source)' alt='gif'/>
                    </body>
                </html>
                """
        }
}

private enum GifLoader {
    static func data(named assetName: String, gifResource: String? = nil) -> Data? {
        if let asset = NSDataAsset(name: assetName) {
            return asset.data
        }

        let resource = gifResource ?? assetName

        if let url = Bundle.main.url(forResource: resource, withExtension: "gif") {
            return try? Data(contentsOf: url)
        }

        return nil
    }

    static var batmanBackgroundData: Data? {
        data(named: "BatmanLevelBackground", gifResource: "batman-level-bg")
    }

    static var spidermanBackgroundData: Data? {
        data(named: "SpidermanLevelBackground", gifResource: "spiderman-level-bg")
    }

    static var totoroBackgroundData: Data? {
        data(named: "totorobg")
    }

    static var pokemonBackgroundData: Data? {
        data(named: "pokemon")
    }

    static var ironmanBackgroundData: Data? {
        data(named: "ironmanbg")
    }

    static var hunterBackgroundData: Data? {
        data(named: "hunterbg")
    }
}

private enum PianoKeyboardLayout {
    struct PianoNoteDescriptor: Identifiable {
        let id: String
        let inputValue: String
        let displayValue: String
        let letterValue: String

        init(note: String, display: String, letter: String) {
            self.id = note
            self.inputValue = note
            self.displayValue = display
            self.letterValue = letter
        }
    }

    struct BlackKeyDescriptor: Identifiable {
        let id = UUID()
        let note: PianoNoteDescriptor
    }

    struct WhiteKeyDescriptor: Identifiable {
        let id = UUID()
        let note: PianoNoteDescriptor
        let color: Color
        let blackKey: BlackKeyDescriptor?
    }

    static let whiteKeys: [WhiteKeyDescriptor] = [
        WhiteKeyDescriptor(
            note: PianoNoteDescriptor(note: "do", display: "Do", letter: "C"),
            color: Color(red: 1.0, green: 0.4, blue: 0.4),
            blackKey: BlackKeyDescriptor(note: PianoNoteDescriptor(note: "do#", display: "Do#", letter: "C#"))
        ),
        WhiteKeyDescriptor(
            note: PianoNoteDescriptor(note: "re", display: "Ré", letter: "D"),
            color: Color(red: 1.0, green: 0.5, blue: 0.3),
            blackKey: BlackKeyDescriptor(note: PianoNoteDescriptor(note: "re#", display: "Ré#", letter: "D#"))
        ),
        WhiteKeyDescriptor(
            note: PianoNoteDescriptor(note: "mi", display: "Mi", letter: "E"),
            color: Color(red: 1.0, green: 0.7, blue: 0.2),
            blackKey: nil
        ),
        WhiteKeyDescriptor(
            note: PianoNoteDescriptor(note: "fa", display: "Fa", letter: "F"),
            color: Color(red: 1.0, green: 0.9, blue: 0.3),
            blackKey: BlackKeyDescriptor(note: PianoNoteDescriptor(note: "fa#", display: "Fa#", letter: "F#"))
        ),
        WhiteKeyDescriptor(
            note: PianoNoteDescriptor(note: "sol", display: "Sol", letter: "G"),
            color: Color(red: 0.6, green: 0.9, blue: 0.3),
            blackKey: BlackKeyDescriptor(note: PianoNoteDescriptor(note: "sol#", display: "Sol#", letter: "G#"))
        ),
        WhiteKeyDescriptor(
            note: PianoNoteDescriptor(note: "la", display: "La", letter: "A"),
            color: Color(red: 0.3, green: 0.8, blue: 0.9),
            blackKey: BlackKeyDescriptor(note: PianoNoteDescriptor(note: "la#", display: "La#", letter: "A#"))
        ),
        WhiteKeyDescriptor(
            note: PianoNoteDescriptor(note: "si", display: "Si", letter: "B"),
            color: Color(red: 0.5, green: 0.5, blue: 1.0),
            blackKey: nil
        )
    ]
}
