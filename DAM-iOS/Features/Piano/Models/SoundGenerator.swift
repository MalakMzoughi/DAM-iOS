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
        let notes = ["do", "re", "mi", "fa", "sol", "la", "si"]
        
        for note in notes {
            // Try multiple ways to find the audio file
            var audioURL: URL?
            
            // Method 1: Try Bundle.main.path
            if let path = Bundle.main.path(forResource: note, ofType: "mp3") {
                audioURL = URL(fileURLWithPath: path)
            }
            // Method 2: Try Bundle.main.url (more reliable)
            else if let url = Bundle.main.url(forResource: note, withExtension: "mp3") {
                audioURL = url
            }
            // Method 3: Try in Resources folder
            else if let url = Bundle.main.url(forResource: note, withExtension: "mp3", subdirectory: "Resources") {
                audioURL = url
            }
            
            if let url = audioURL {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = 0.8
                    audioPlayers[note] = player
                    print("✅ Loaded: \(note).mp3 from \(url.lastPathComponent)")
                } catch {
                    print("❌ Cannot load \(note).mp3: \(error)")
                }
            } else {
                print("⚠️ File not found: \(note).mp3 - Check if file is added to project and target membership")
            }
        }
    }
    
    // Play a note by name (do, re, mi, etc.)
    func playNote(noteName: String) {
        let normalizedNote = noteName.lowercased()
        
        guard let player = audioPlayers[normalizedNote] else {
            print("❌ No audio player for: \(noteName)")
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
}

