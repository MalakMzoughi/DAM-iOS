//
//  SoundGenerator.swift
//  DAM-iOS
//
//  VERSION WITH AUDIO FILES (Most Reliable)
//

import Foundation
import AVFoundation

class SoundGenerator {
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let noteSampleMap: [String: String] = [
        "do": "do", "c": "do", "b#": "do",
        "do#": "c_sharp", "c#": "c_sharp", "reb": "c_sharp",
        "re": "re", "d": "re",
        "re#": "d_sharp", "d#": "d_sharp", "mib": "d_sharp",
        "mi": "mi", "e": "mi", "fb": "mi",
        "fa": "fa", "f": "fa", "e#": "fa",
        "fa#": "f_sharp", "f#": "f_sharp", "solb": "f_sharp",
        "sol": "sol", "g": "sol",
        "sol#": "g_sharp", "g#": "g_sharp", "lab": "g_sharp",
        "la": "la", "a": "la",
        "la#": "a_sharp", "a#": "a_sharp", "sib": "a_sharp",
        "si": "si", "b": "si", "cb": "si"
    ]
    
    init() {
        // Setup audio session - use .playAndRecord to work with microphone
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            print("✅ SoundGenerator: Audio session configured for playAndRecord")
        } catch {
            print("❌ Audio session error: \(error)")
        }
        
        // Preload all piano sounds
        preloadSounds()
    }
    
    // Preload audio files for better performance
    private func preloadSounds() {
        let samples = Set(noteSampleMap.values)
        
        for sample in samples {
            guard let url = locateAudioFile(named: sample) else {
                print("⚠️ File not found: \(sample).mp3 - Check if file is added to project and target membership")
                continue
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = 0.8
                audioPlayers[sample] = player
                print("✅ Loaded: \(sample).mp3 from \(url.lastPathComponent)")
            } catch {
                print("❌ Cannot load \(sample).mp3: \(error)")
            }
        }
    }
    
    // Play a note by name (do, re, mi, etc.)
    func playNote(noteName: String) {
        let normalizedNote = normalizeNoteName(noteName)
        guard let sampleName = noteSampleMap[normalizedNote] else {
            print("❌ No sample mapping for: \(noteName)")
            return
        }
        
        guard let player = audioPlayers[sampleName] else {
            print("❌ No audio player for: \(sampleName)")
            return
        }
        
        // Reset to beginning if already playing
        player.currentTime = 0
        player.play()
        print("🎹 Playing: \(noteName)")
    }
    
    // Play note by frequency (for backward compatibility)
    func playNote(frequency: Double, duration: Double = 0.5) {
        // Map frequency to note name
        let noteMap: [Double: String] = [
            261.63: "do",
            293.66: "re",
            329.63: "mi",
            349.23: "fa",
            392.00: "sol",
            440.00: "la",
            493.88: "si"
        ]
        
        // Find closest frequency
        if let noteName = noteMap[frequency] {
            playNote(noteName: noteName)
        }
    }
    
    // Stop all sounds
    func stop() {
        audioPlayers.values.forEach { $0.stop() }
    }

    // Normalize various note spellings (accents, symbols, language variants)
    private func normalizeNoteName(_ raw: String) -> String {
        raw.lowercased()
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "è", with: "e")
            .replacingOccurrences(of: "ê", with: "e")
            .replacingOccurrences(of: "à", with: "a")
            .replacingOccurrences(of: "ù", with: "u")
            .replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "♭", with: "b")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
    
    private func locateAudioFile(named resource: String) -> URL? {
        if let path = Bundle.main.path(forResource: resource, ofType: "mp3") {
            return URL(fileURLWithPath: path)
        }
        if let url = Bundle.main.url(forResource: resource, withExtension: "mp3") {
            return url
        }
        if let url = Bundle.main.url(forResource: resource, withExtension: "mp3", subdirectory: "Resources") {
            return url
        }
        return nil
    }
}

