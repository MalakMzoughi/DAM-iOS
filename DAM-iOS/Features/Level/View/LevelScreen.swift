//
//  LevelScreen.swift
//  DAM-iOS
//
//  Fixed layout to match Android version
//

import SwiftUI
import AVFoundation
import Foundation

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
    
    let level: Level
    let sublevel: Sublevel
    private let showsIntroAndSublevelSelection: Bool

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
                    musicUrl: level.musicUrl,
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
            let repo = SublevelRepository()
            if let sublevels = await repo.getSublevelsByLevel(level.id) {
                await MainActor.run {
                    self.allSublevels = sublevels.sorted { $0.index < $1.index }
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
    private func resetLevel() {
        showFailDialog = false
        viewModel.reset()
        if pianoMode == .realPiano {
            pitchDetector.startListening()
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
    
    // --------------------------------------------------
    // GAMEPLAY UI - FIXED LAYOUT
    // --------------------------------------------------
    private var gameplayUI: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // TOP BAR: Score + Lives
                HStack {
                    HStack(spacing: 6) {
                        Text("Score:")
                            .font(.system(size: 14, weight: .semibold))
                        Text("\(viewModel.score)")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.purple.opacity(0.85))
                    )
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: "heart.fill")
                                .foregroundColor(index < viewModel.lives ? .red : Color.white.opacity(0.3))
                                .font(.system(size: 24))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .frame(height: 60)
                
                // MAIN GAME AREA: Hero + Lanes + Boss
                // Calculate available height for game area
                let bottomSectionHeight: CGFloat = 160
                let topBarHeight: CGFloat = 60
                let gameAreaHeight = geometry.size.height - topBarHeight - bottomSectionHeight
                
                HStack(alignment: .top, spacing: 6) {
                    // HERO CARD
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(heroImageName(for: level.theme))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 130)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.cyan, lineWidth: 2)
                                )
                            
                            Circle()
                                .fill(Color.green)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 12, weight: .bold))
                                )
                                .offset(x: 6, y: -6)
                        }
                        
                        Text("HERO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.orange.opacity(0.8))
                            )
                    }
                    .frame(width: 90)
                    
                    // VERTICAL LANES WITH FALLING NOTES
                    verticalLanesView(geometry: geometry)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // BOSS CARD
                    VStack(spacing: 4) {
                        if let bossURL = level.bossUrl, let url = URL(string: bossURL) {
                            AsyncImage(url: url) { img in
                                img.resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color.purple.opacity(0.3)
                            }
                            .frame(width: 90, height: 130)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red, lineWidth: 2)
                            )
                        }
                        
                        Text("BOSS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.red.opacity(0.8))
                            )
                    }
                    .frame(width: 90)
                }
                .padding(.horizontal, 8)
                .frame(height: gameAreaHeight)
                
                // BOTTOM SECTION: Progress + Mode Buttons + Piano/Mic
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        // PROGRESS
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                )
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Progress:")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(Int(viewModel.progress * 100))%")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.08))
                        )
                        
                        Spacer()
                        
                        // MODE BUTTONS
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
                    .frame(height: 60)
                    
                    // CONDITIONAL UI: PIANO KEYBOARD OR MICROPHONE
                    if pianoMode == .appPiano {
                        pianoKeyboardView
                            .frame(height: 100)
                            .padding(.horizontal, 6)
                            .transition(.opacity)
                    } else {
                        microphoneIndicatorView
                            .frame(height: 100)
                            .padding(.horizontal, 6)
                            .transition(.opacity)
                    }
                }
                .frame(height: bottomSectionHeight)
                .padding(.bottom, 4)
            }
        }
    }
    
    // --------------------------------------------------
    // VERTICAL LANES VIEW - PROPER SIZING
    // --------------------------------------------------
    private func verticalLanesView(geometry: GeometryProxy) -> some View {
        let notes = currentSublevel?.notes ?? sublevel.notes
        
        return ZStack {
            // 7 VERTICAL LANES
            HStack(spacing: 2) {
                ForEach(0..<7) { laneIndex in
                    VStack {
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(laneColor(for: laneIndex).opacity(0.25))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // FALLING NOTES
            GeometryReader { geo in
                ForEach(0..<notes.count, id: \.self) { index in
                    if index >= viewModel.currentIndex && index < viewModel.currentIndex + 4 {
                        noteBadge(for: notes[index])
                            .position(
                                x: laneXPosition(for: noteLane(notes[index]), width: geo.size.width),
                                y: noteYPosition(for: index - viewModel.currentIndex, height: geo.size.height)
                            )
                    }
                }
            }
        }
    }
    
    // --------------------------------------------------
    // NOTE BADGE
    // --------------------------------------------------
    private func noteBadge(for note: String) -> some View {
        Text(note.uppercased())
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
    }
    
    // --------------------------------------------------
    // MODE BUTTON - COMPACT
    // --------------------------------------------------
    private func modeButton(icon: String, label: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : Color.gray.opacity(0.3))
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
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.5), lineWidth: 2)
                    )
            )
        }
    }
    
    // --------------------------------------------------
    // PIANO KEYBOARD VIEW - COMPACT
    // --------------------------------------------------
    private var pianoKeyboardView: some View {
        HStack(spacing: 1) {
            pianoKey(note: "do", label: "Do", color: Color(red: 1.0, green: 0.4, blue: 0.4), hasBlackKey: false)
            pianoKey(note: "re", label: "Ré", color: Color(red: 1.0, green: 0.5, blue: 0.3), hasBlackKey: true)
            pianoKey(note: "mi", label: "Mi", color: Color(red: 1.0, green: 0.7, blue: 0.2), hasBlackKey: false)
            pianoKey(note: "fa", label: "Fa", color: Color(red: 1.0, green: 0.9, blue: 0.3), hasBlackKey: true)
            pianoKey(note: "sol", label: "Sol", color: Color(red: 0.6, green: 0.9, blue: 0.3), hasBlackKey: true)
            pianoKey(note: "la", label: "La", color: Color(red: 0.3, green: 0.8, blue: 0.9), hasBlackKey: true)
            pianoKey(note: "si", label: "Si", color: Color(red: 0.5, green: 0.5, blue: 1.0), hasBlackKey: false)
        }
    }
    
    // --------------------------------------------------
    // PIANO KEY - COMPACT VERSION
    // --------------------------------------------------
    @ViewBuilder
    private func pianoKey(note: String, label: String, color: Color, hasBlackKey: Bool) -> some View {
        Button(action: {
            handleKeyPress(note)
        }) {
            ZStack {
                // WHITE KEY BACKGROUND
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                
                // BLACK KEY (TOP)
                if hasBlackKey {
                    VStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black)
                            .frame(width: 20, height: 30)
                            .offset(y: -10)
                        
                        Spacer()
                    }
                }
                
                // NOTE LABEL (BOTTOM)
                VStack {
                    Spacer()
                    Text(label)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.bottom, 6)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // --------------------------------------------------
    // HELPER: HANDLE KEY PRESS
    // --------------------------------------------------
    private func handleKeyPress(_ note: String) {
        if pianoMode == .appPiano {
            soundGen.playNote(noteName: note)
        }
        viewModel.onNotePlayed(note)
    }
    
    // --------------------------------------------------
    // HELPER: LANE COLOR
    // --------------------------------------------------
    private func laneColor(for index: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.8, green: 0.2, blue: 0.2),
            Color(red: 0.5, green: 0.3, blue: 0.2),
            Color(red: 0.3, green: 0.3, blue: 0.3),
            Color(red: 0.7, green: 0.6, blue: 0.2),
            Color(red: 0.2, green: 0.6, blue: 0.3),
            Color(red: 0.2, green: 0.4, blue: 0.7),
            Color(red: 0.5, green: 0.3, blue: 0.7),
        ]
        return colors[index % colors.count]
    }
    
    // --------------------------------------------------
    // HELPER: NOTE LANE
    // --------------------------------------------------
    private func noteLane(_ note: String) -> Int {
        switch note.lowercased() {
        case "do": return 0
        case "re", "ré": return 1
        case "mi": return 2
        case "fa": return 3
        case "sol": return 4
        case "la": return 5
        case "si": return 6
        default: return 0
        }
    }
    
    // --------------------------------------------------
    // HELPER: LANE X POSITION
    // --------------------------------------------------
    private func laneXPosition(for lane: Int, width: CGFloat) -> CGFloat {
        let laneWidth = width / 7
        return laneWidth * CGFloat(lane) + laneWidth / 2
    }
    
    // --------------------------------------------------
    // HELPER: NOTE Y POSITION
    // --------------------------------------------------
    private func noteYPosition(for offset: Int, height: CGFloat) -> CGFloat {
        let spacing = height / 5
        return spacing * CGFloat(offset + 1)
    }
    
    // --------------------------------------------------
    // BACKGROUND
    // --------------------------------------------------
    private var backgroundLayer: some View {
        ZStack {
            if let bg = level.backgroundUrl, let url = URL(string: bg) {
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
                        colors: [
                            Color.black.opacity(0.1),
                            Color.black.opacity(0.75)
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

            if userSession.isLoggedIn {
                let success = await viewModel.saveProgress(userId: userSession.profile.id)
                print("LevelScreen: saveProgress success = \(success)")
            } else {
                print("LevelScreen: guest mode – not saving progress")
            }

            await MainActor.run {
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
    
    private func calculateStars(_ score: Int) -> Int {
        switch score {
        case 85...: return 3
        case 60...: return 2
        case 30...: return 1
        default: return 0
        }
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
    let musicUrl: String?
    var onDismiss: () -> Void
    
    @State private var isPlaying = false
    @State private var player: AVPlayer?
    @State private var statusObserver: NSKeyValueObservation?
    @State private var showLoadingSpinner = false
    @State private var errorMessage: String?
    
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
                    Button(action: playPreview) {
                        HStack(spacing: 12) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 32))
                            Text(isPlaying ? "Playing..." : "Play Theme")
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
        .onAppear { playPreview() }
        .onDisappear {
            player?.pause()
            statusObserver = nil
        }
    }
    
    private func playPreview() {
        guard let audioURL = Bundle.main.url(forResource: "batman-preview", withExtension: "mp3") else {
            errorMessage = "Audio file not found in bundle"
            return
        }

        showLoadingSpinner = true
        errorMessage = nil

        let playerItem = AVPlayerItem(url: audioURL)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player

        NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: playerItem, queue: .main) { _ in
            isPlaying = false
            showLoadingSpinner = false
            errorMessage = "Unable to play preview."
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
}
