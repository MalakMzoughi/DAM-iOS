//
//  PianoViewModel.swift
//  DAM-iOS
//
//  Updated to work with audio files
//

import Foundation
import Combine
import SwiftUI

class PianoViewModel: ObservableObject {
    @Published var keys: [PianoKey] = []
    @Published var currentLevel: Int = 1
    
    // Beginner note sequence (Do-Re-Mi-Fa-Sol-La-Si)
    var beginnerSequence: [String] {
        return ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"]
    }
    
    private let soundGenerator = SoundGenerator()
    
    init(level: Int) {
        self.currentLevel = level
        loadKeysForLevel(level)
    }
    
    func loadKeysForLevel(_ level: Int) {
        switch level {
        case 1:
            keys = generateLevel1Keys()
        case 2:
            keys = generateLevel2Keys()
        case 3:
            keys = generateLevel3Keys()
        default:
            keys = generateLevel1Keys()
        }
    }
    
    // Play a key using AUDIO FILES
    func playKey(_ key: PianoKey) {
        // Use the note name directly (do, re, mi, etc.)
        let noteName = key.note.lowercased()
        soundGenerator.playNote(noteName: noteName)
        print("🎹 Playing: \(key.note)")
    }
    
    // MARK: - Level 1 Keys
    private func generateLevel1Keys() -> [PianoKey] {
        return [
            PianoKey(
                note: "Do",
                octave: 4,
                type: .white,
                frequency: 261.63,
                color: Color(red: 1.0, green: 0.3, blue: 0.3)
            ),
            PianoKey(
                note: "Re",
                octave: 4,
                type: .white,
                frequency: 293.66,
                color: Color.orange
            ),
            PianoKey(
                note: "Mi",
                octave: 4,
                type: .white,
                frequency: 329.63,
                color: Color.yellow
            ),
            PianoKey(
                note: "Fa",
                octave: 4,
                type: .white,
                frequency: 349.23,
                color: Color.green
            ),
            PianoKey(
                note: "Sol",
                octave: 4,
                type: .white,
                frequency: 392.00,
                color: Color.cyan
            ),
            PianoKey(
                note: "La",
                octave: 4,
                type: .white,
                frequency: 440.00,
                color: Color.blue
            ),
            PianoKey(
                note: "Si",
                octave: 4,
                type: .white,
                frequency: 493.88,
                color: Color.purple
            )
        ]
    }
    
    private func generateLevel2Keys() -> [PianoKey] {
        var keys = generateLevel1Keys()
        keys.append(PianoKey(
            note: "Do",
            octave: 5,
            type: .white,
            frequency: 523.25,
            color: Color(red: 1.0, green: 0.5, blue: 0.5)
        ))
        return keys
    }
    
    private func generateLevel3Keys() -> [PianoKey] {
        return generateLevel1Keys()
    }
    
    deinit {
        soundGenerator.stop()
    }
}

