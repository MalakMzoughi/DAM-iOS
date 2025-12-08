//
//  LevelViewModel.swift
//  DAM-iOS
//
//  Gameplay logic for a level
//

import Foundation
import SwiftUI

@MainActor
class LevelViewModel: ObservableObject {
    
    // ------------------------------------------------------
    // INPUT
    // ------------------------------------------------------
    let level: Level
    @Published private(set) var currentSublevel: Sublevel
    private let progressRepo = SublevelProgressRepository()
    private var expectedNotes: [String]

    
    // ------------------------------------------------------
    // PUBLIC STATE (UI observes this)
    // ------------------------------------------------------
    @Published var currentIndex: Int = 0
    @Published var score: Int = 0
    @Published var lives: Int = 3
    @Published var mistakes: Int = 0
    @Published var resetStamp = UUID()
    
    @Published var wrongMessage: String? = nil
    @Published var isLevelCompleted: Bool = false
    @Published var isFailed: Bool = false
    
    // For progress bar: 0.0 → 1.0
    @Published var progress: Double = 0.0
    
    // Keyboard keys (7 colored notes)
    @Published var keys: [PianoKey] = []
    
    // ------------------------------------------------------
    // INIT
    // ------------------------------------------------------
    init(level: Level, sublevel: Sublevel) {
        self.level = level
        self.currentSublevel = sublevel
        self.expectedNotes = sublevel.notes
        setupKeys()
        updateProgress()
    }

    // ------------------------------------------------------
    // LOAD NEW SUBLEVEL
    // ------------------------------------------------------
    func loadSublevel(_ sublevel: Sublevel) {
        currentSublevel = sublevel
        reset()
    }
    
    // ------------------------------------------------------
    // SETUP KEYS
    // ------------------------------------------------------
    private func setupKeys() {
        // Your standard 7-note keyboard
        keys = [
            PianoKey(note: "do", octave: 4, type: .white, frequency: 261.63, color: .red),
            PianoKey(note: "re", octave: 4, type: .white, frequency: 293.66, color: .orange),
            PianoKey(note: "mi", octave: 4, type: .white, frequency: 329.63, color: .yellow),
            PianoKey(note: "fa", octave: 4, type: .white, frequency: 349.23, color: .green),
            PianoKey(note: "sol", octave: 4, type: .white, frequency: 392.00, color: .cyan),
            PianoKey(note: "la", octave: 4, type: .white, frequency: 440.00, color: .blue),
            PianoKey(note: "si", octave: 4, type: .white, frequency: 493.88, color: .purple)
        ]
    }
    
    // ------------------------------------------------------
    // NEXT EXPECTED NOTE
    // ------------------------------------------------------
    var nextNote: String? {
        guard currentIndex < expectedNotes.count else { return nil }
        return expectedNotes[currentIndex]
    }
    
    // ------------------------------------------------------
    // PLAYER PRESSED A NOTE
    // ------------------------------------------------------
    func onNotePlayed(_ note: String) {
        guard let expected = nextNote else { return }
        
        let normalizedExpected = normalize(expected)
        let normalizedPlayed = normalize(note)
        
        if normalizedPlayed == normalizedExpected {
            handleCorrectNote()
        } else {
            handleWrongNote()
        }
    }
    
    // ------------------------------------------------------
    // CORRECT NOTE
    // ------------------------------------------------------
    private func handleCorrectNote() {
        wrongMessage = nil
        score += 10
        currentIndex += 1
        
        updateProgress()
        
        // Level completed - delay slightly so last note sound plays
        if currentIndex >= expectedNotes.count {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                isLevelCompleted = true
            }
        }
    }
    
    // ------------------------------------------------------
    // WRONG NOTE
    // ------------------------------------------------------
    private func handleWrongNote() {
        mistakes += 1
        lives = max(0, 3 - mistakes)
        wrongMessage = "Incorrect! Try again 🎵"
        
        if mistakes >= 3 {
            isFailed = true
        }
    }
    
    // ------------------------------------------------------
    // PROGRESS BAR
    // ------------------------------------------------------
    private func updateProgress() {
        guard !expectedNotes.isEmpty else {
            progress = 0
            return
        }
        progress = Double(currentIndex) / Double(expectedNotes.count)
    }

    // Current star count derived from mistakes (Android parity)
    var starsEarned: Int {
        switch mistakes {
        case 0: return 3
        case 1: return 2
        case 2: return 1
        default: return 0
        }
    }
    
    // ------------------------------------------------------
    // RESET
    // ------------------------------------------------------
    func reset() {
        currentIndex = 0
        score = 0
        lives = 3
        mistakes = 0
        wrongMessage = nil
        isLevelCompleted = false
        isFailed = false
        expectedNotes = currentSublevel.notes
        updateProgress()
        resetStamp = UUID()
    }
    
    // ------------------------------------------------------
    // SAVE PROGRESS (calls backend /sublevels/progress)
    // ------------------------------------------------------
    func saveProgress(userId: String) async -> [Sublevel]? {
        let request = SublevelProgressRequest(
            userId: userId,
            levelId: level.id,
            sublevelId: currentSublevel.id,
            stars: starsEarned,
            score: score,
            completed: true
        )

        guard let updated = await progressRepo.saveProgress(request) else {
            print("⚠️ LevelViewModel.saveProgress – failed to save sublevel progress")
            return nil
        }

        if let refreshed = updated.first(where: { $0.id == currentSublevel.id }) {
            currentSublevel = refreshed
        }

        print("✅ LevelViewModel.saveProgress – saved progress for sublevel \(currentSublevel.id)")
        return updated.sorted { $0.index < $1.index }
    }

    
    // ------------------------------------------------------
    // NORMALIZATION
    // ------------------------------------------------------
    private func normalize(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "è", with: "e")
            .replacingOccurrences(of: "ê", with: "e")
            .replacingOccurrences(of: "à", with: "a")
            .replacingOccurrences(of: "ù", with: "u")
            .replacingOccurrences(of: "ô", with: "o")
    }
}
