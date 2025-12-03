//
//  LevelScreen.swift
//  DAM-iOS
//
//  Updated to properly navigate back to home after completion
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
    
    @State private var showSuccessDialog = false
    @State private var showFailDialog = false
    @State private var pianoMode: PianoMode = .appPiano
    @State private var microphonePermissionDenied = false
    
    let level: Level
    let sublevel: Sublevel

    init(level: Level, sublevel: Sublevel, pianoMode: PianoMode = .appPiano) {
        self.level = level
        self.sublevel = sublevel
        _pianoMode = State(initialValue: pianoMode)
        _viewModel = StateObject(wrappedValue: LevelViewModel(level: level, sublevel: sublevel))
    }
    
    // --------------------------------------------------
    // BODY
    // --------------------------------------------------
    var body: some View {
        mainContent
            .onChange(of: viewModel.isLevelCompleted, perform: handleLevelCompletion)
            .onChange(of: viewModel.isFailed, perform: handleLevelFailure)
            .onChange(of: pitchDetector.detectionEvent, perform: handleDetectionEvent)
        .onAppear {
            if pianoMode == .realPiano {
                startMicrophoneListening()
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
        
        // FAIL ALERT
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
                router.current = .home  // Use router instead of dismiss
            }
        } message: {
            Text("You've run out of lives. Try again!")
        }
        
        // MICROPHONE PERMISSION ALERT
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
    // MAIN CONTENT
    // --------------------------------------------------
    private var mainContent: some View {
        ZStack {
            backgroundLayer
            gameplayUI
            if showSuccessDialog {
                LevelCompletedDialogView(stars: viewModel.starsEarned) {
                    showSuccessDialog = false
                    router.current = .home
                }
                .transition(.opacity)
                .zIndex(1)
            }
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
            return "heroBatman" // Fallback - add heroSuperman asset if available
        case "captain america", "captainamerica":
            return "heroBatman" // Fallback - add heroCaptainAmerica asset if available
        case "magical girl", "magicalgirl":
            return "heroSpiderman" // Fallback - add heroMagicalGirl asset if available
        case "pirate":
            return "heroBatman" // Fallback - add heroPirate asset if available
        case "totoro", "my neighbor totoro":
            return "heroSpiderman" // Fallback
        case "pokemon", "pokémon":
            return "heroSpiderman" // Fallback
        case "marvel heroes", "marvel-heroes":
            return "heroSpiderman" // Fallback
        case "hunter x hunter", "hunterxhunter", "hxh":
            return "heroSpiderman" // Fallback
        default:
            return "heroBatman" // Default fallback
        }
    }
    
    // --------------------------------------------------
    // GAMEPLAY UI
    // --------------------------------------------------
    private var gameplayUI: some View {
        VStack(spacing: 0) {
            
            headerBar
            
            Spacer().frame(height: 20)
            
            heroAndBoss
            
            Spacer().frame(height: 10)
            
            progressSection
            
            wrongNoteMessage
            
            Spacer().frame(height: 30)
            
            nextNoteSection
            
            Spacer()
            
            pianoKeyboard
            
        }
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
                        colors: [.black.opacity(0.3), .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
        }
    }
    
    // --------------------------------------------------
    // HEADER BAR
    // --------------------------------------------------
    private var headerBar: some View {
        HStack {
            Button {
                router.current = .home  // Use router instead of dismiss
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Level \(level.order) · Sublevel \(sublevel.index)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(sublevel.trackName ?? level.title)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            scoreBadge
        }
        .padding(.horizontal, 20)
    }
    
    private var scoreBadge: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text("\(viewModel.score)")
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .bold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.55))
        .cornerRadius(20)
    }
    
    // --------------------------------------------------
    // HERO + BOSS
    // --------------------------------------------------
    private var heroAndBoss: some View {
        HStack {
            heroCard
            Spacer()
            bossCard
        }
        .padding(.horizontal, 20)
    }
    
    private var heroCard: some View {
        VStack(spacing: 10) {
            // Try different avatar sources before falling back to hero image
            if let avatar = userSession.activeAvatar {
                if let urlString = avatar.avatarImageUrl,
                   let url = URL(string: urlString)
                {
                    AsyncImage(url: url) { img in
                        img.resizable()
                    } placeholder: { ProgressView() }
                    .frame(width: 140, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                else {
                    // Fallback to theme-based hero image
                    Image(heroImageName(for: level.theme))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            } else {
                // No active avatar → fallback hero
                Image(heroImageName(for: level.theme))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            Text("HERO")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .bold))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.5))
        )
    }

    private func handleLevelCompletion(_ completed: Bool) {
        guard completed else { return }
        Task {
            await MainActor.run {
                if pianoMode == .realPiano {
                    pitchDetector.stopListening()
                } else {
                    soundGen.stop()
                }
            }

            if userSession.isLoggedIn {
                let userId = userSession.profile.id
                let success = await viewModel.saveProgress(userId: userId)
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

    
    private var bossCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < viewModel.lives ? "heart.fill" : "heart")
                        .foregroundColor(index < viewModel.lives ? .red : .white.opacity(0.5))
                        .font(.system(size: 18, weight: .bold))
                }
            }

            if let bossURL = level.bossUrl, let url = URL(string: bossURL) {
                AsyncImage(url: url) { img in
                    img.resizable()
                } placeholder: { ProgressView() }
                .frame(width: 140, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 140, height: 180)
                    .overlay {
                        Image(systemName: "person.crop.square")
                            .resizable()
                            .scaledToFit()
                            .padding(24)
                            .foregroundColor(.white.opacity(0.8))
                    }
            }
            
            Text("BOSS")
                .foregroundColor(.red)
                .font(.system(size: 16, weight: .bold))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.5))
        )
    }
    
    // --------------------------------------------------
    // PROGRESS BAR
    // --------------------------------------------------
    private var progressSection: some View {
        VStack(alignment: .leading) {
            Text("Progress: \(Int(viewModel.progress * 100))%")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .bold))
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 20)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, viewModel.progress) * UIScreen.main.bounds.width * 0.9, height: 20)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // --------------------------------------------------
    // WRONG NOTE MESSAGE
    // --------------------------------------------------
    private var wrongNoteMessage: some View {
        if let msg = viewModel.wrongMessage {
            return AnyView(
                Text(msg)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(14)
                    .padding(.top, 10)
            )
        }
        return AnyView(EmptyView())
    }
    
    // --------------------------------------------------
    // NEXT NOTE
    // --------------------------------------------------
    private var nextNoteSection: some View {
        VStack {
            Text("Next Note")
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 16))
            
            Text(viewModel.nextNote?.uppercased() ?? "🎉")
                .foregroundColor(.white)
                .font(.system(size: 40, weight: .bold))
                .padding()
                .background(Circle().fill(Color.blue.opacity(0.7)))
        }
    }
    
    // --------------------------------------------------
    // PIANO KEYBOARD OR MICROPHONE INDICATOR
    // --------------------------------------------------
    private var pianoKeyboard: some View {
        Group {
            if pianoMode == .appPiano {
                // Virtual keyboard
                PianoKeyboardView(keys: viewModel.keys) { key in
                    let played = normalize(key.note)
                    soundGen.playNote(noteName: played)
                    viewModel.onNotePlayed(played)
                }
                .padding(.horizontal, 20)
            } else {
                // Microphone listening mode
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(pitchDetector.isListening ? Color.red : Color.gray)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        Text(pitchDetector.isListening ? "🎤 Listening..." : "🎤 Mic Off")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    
                    // Show detected note
                    if !pitchDetector.detectedNote.isEmpty {
                        VStack(spacing: 8) {
                            Text("Detected:")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(pitchDetector.detectedNote.uppercased())
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.cyan)
                                .padding()
                                .background(Circle().fill(Color.white.opacity(0.2)))
                            
                            Text("\(Int(pitchDetector.detectedFrequency)) Hz")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(16)
                    }
                    
                    Text("Play the notes on your real piano or instrument")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
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
