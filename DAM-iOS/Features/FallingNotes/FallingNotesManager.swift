//
//  FallingNotesManager.swift
//  Falling Notes System
//
//  Created on 2025-12-06.
//

import SwiftUI
import Combine

/// Manages the falling notes animation and gameplay logic
class FallingNotesManager: ObservableObject {
    @Published var fallingNotes: [FallingNote] = []
    private var lastUpdateTime: TimeInterval = 0
    private var currentTime: TimeInterval = 0
    
    // Configuration
    let fallDuration: TimeInterval = 3.0 // Time for note to fall from top to bottom
    var screenHeight: CGFloat = 800
    var keyboardHeight: CGFloat = 100
    
    /// Start the animation loop
    func startAnimating() {
        lastUpdateTime = Date().timeIntervalSince1970
        scheduleUpdate()
    }
    
    /// Update all falling notes positions
    func update() {
        let now = Date().timeIntervalSince1970
        let deltaTime = now - lastUpdateTime
        lastUpdateTime = now
        currentTime = now
        
        // Update positions
        for index in fallingNotes.indices {
            let distancePerSecond = (screenHeight + 200) / CGFloat(fallDuration)
            fallingNotes[index].yPosition += distancePerSecond * CGFloat(deltaTime)
        }
        
        // Remove notes that have passed the bottom
        fallingNotes.removeAll { note in
            note.yPosition > screenHeight + 100
        }
        
        scheduleUpdate()
    }
    
    private func scheduleUpdate() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 16_000_000) // ~60 FPS
            self.update()
        }
    }
    
    /// Add a new falling note
    func addNote(_ note: MusicNote, targetTime: TimeInterval = 0) {
        let fallingNote = FallingNote(
            note: note,
            lane: note.lane,
            speed: 200,
            targetTime: targetTime
        )
        fallingNotes.append(fallingNote)
    }
    
    /// Load a sequence of notes (for testing or gameplay)
    func loadNoteSequence(_ notes: [MusicNote], interval: TimeInterval = 1.0) {
        for (index, note) in notes.enumerated() {
            let delay = TimeInterval(index) * interval
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                self.addNote(note)
            }
        }
    }
    
    /// Check if a note was hit successfully
    func checkNoteHit(lane: Int) -> Bool {
        let hitZone: ClosedRange<CGFloat> = (screenHeight - keyboardHeight - 100)...(screenHeight - keyboardHeight + 50)
        
        if let index = fallingNotes.firstIndex(where: { note in
            note.lane == lane && hitZone.contains(note.yPosition)
        }) {
            fallingNotes.remove(at: index)
            return true
        }
        return false
    }
    
    /// Remove all notes
    func clearAllNotes() {
        fallingNotes.removeAll()
    }
}
