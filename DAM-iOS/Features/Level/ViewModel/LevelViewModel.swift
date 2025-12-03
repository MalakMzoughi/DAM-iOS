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
    private let repo = LevelRepository()

    
    // ------------------------------------------------------
    // PUBLIC STATE (UI observes this)
    // ------------------------------------------------------
    @Published var currentIndex: Int = 0
    @Published var score: Int = 0
    @Published var lives: Int = 3
    
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
    init(level: Level) {
        self.level = level
        setupKeys()
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
        guard currentIndex < level.expectedNotes.count else { return nil }
        return level.expectedNotes[currentIndex]
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
        
        // Level completed
        if currentIndex >= level.expectedNotes.count {
            isLevelCompleted = true
        }
    }
    
    // ------------------------------------------------------
    // WRONG NOTE
    // ------------------------------------------------------
    private func handleWrongNote() {
        lives -= 1
        wrongMessage = "Incorrect! Try again 🎵"
        
        if lives <= 0 {
            isFailed = true
        }
    }
    
    // ------------------------------------------------------
    // PROGRESS BAR
    // ------------------------------------------------------
    private func updateProgress() {
        let total = Double(level.expectedNotes.count)
        progress = Double(currentIndex) / total
    }

    // Current star count based on score (used by UI)
    var starsEarned: Int {
        calculateStars(from: score)
    }
    
    // ------------------------------------------------------
    // RESET
    // ------------------------------------------------------
    func reset() {
        currentIndex = 0
        score = 0
        lives = 3
        wrongMessage = nil
        isLevelCompleted = false
        isFailed = false
        updateProgress()
    }
    
    // ------------------------------------------------------
    // SAVE PROGRESS (calls backend /levels/progress)
    // ------------------------------------------------------
    func saveProgress(userId: String) async -> Bool {
        let stars = calculateStars(from: score)

        let request = LevelProgressRequest(
            userId: userId,
            levelId: level.id,
            stars: stars,
            score: score,
            completed: true
        )

        let success = await repo.saveProgress(request)
        if success {
            print("✅ LevelViewModel.saveProgress – saved progress for level \(level.id)")
        } else {
            print("⚠️ LevelViewModel.saveProgress – failed to save progress")
        }
        return success
    }

    // Same thresholds as Android & LevelScreen
    private func calculateStars(from score: Int) -> Int {
        switch score {
        case 85...: return 3
        case 60...: return 2
        case 30...: return 1
        default: return 0
        }
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
