//
//  GamePlayView.swift
//  Falling Notes System - Main Game View
//
//  Created on 2025-12-06.
//

import SwiftUI

/// Main gameplay view with falling notes system
struct GamePlayView: View {
    @State private var notesManager = FallingNotesManager()
    @State private var score: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Score Display
                    HStack {
                        Text("Score: \(score)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                        Spacer()
                    }
                    .frame(height: 60)
                    
                    // Falling Notes Area
                    NoteLanesView(
                        fallingNotes: $notesManager.fallingNotes,
                        screenHeight: geometry.size.height,
                        keyboardHeight: 120
                    )
                    .frame(height: geometry.size.height - 180)
                    
                    // Piano Keyboard
                    FallingNotesPianoKeyboard { note in
                        handleKeyPress(note)
                    }
                    .frame(height: 120)
                }
            }
            .onAppear {
                notesManager.screenHeight = geometry.size.height
                notesManager.keyboardHeight = 120
                notesManager.startAnimating()
                
                // Demo: Load a test sequence
                loadDemoSequence()
            }
        }
    }
    
    private func handleKeyPress(_ note: MusicNote) {
        let isHit = notesManager.checkNoteHit(lane: note.lane)
        if isHit {
            score += 10
            // Add haptic feedback here if desired
        }
    }
    
    private func loadDemoSequence() {
        // Demo sequence - replace with your actual song data
        let sequence: [MusicNote] = [
            .DO, .RE, .MI, .FA, .SOL, .LA, .SI,
            .SI, .LA, .SOL, .FA, .MI, .RE, .DO,
            .DO, .MI, .SOL, .MI, .DO,
            .RE, .FA, .LA, .FA, .RE
        ]
        
        notesManager.loadNoteSequence(sequence, interval: 1.2)
    }
}

/// Piano keyboard view with 7 keys for falling notes game
struct FallingNotesPianoKeyboard: View {
    let onKeyPress: (MusicNote) -> Void
    
    private let notes = MusicNote.allCases
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(notes, id: \.self) { note in
                    FallingNotesPianoKey(note: note) {
                        onKeyPress(note)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .background(Color.black.opacity(0.8))
    }
}

/// Individual piano key for falling notes game
struct FallingNotesPianoKey: View {
    let note: MusicNote
    let onPress: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            onPress()
            
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000)
                isPressed = false
            }
        }) {
            VStack(spacing: 4) {
                Spacer()
                
                Text(note.displayName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Circle()
                    .fill(note.color)
                    .frame(width: 30, height: 30)
                    .shadow(color: note.color.opacity(0.8), radius: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPressed ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(note.color.opacity(0.5), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GamePlayView()
}
