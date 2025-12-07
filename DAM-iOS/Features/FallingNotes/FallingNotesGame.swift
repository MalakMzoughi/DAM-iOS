//
//  FallingNotesGame.swift
//  DAM-iOS
//
//  Complete falling notes piano game UI components
//  All-in-one file for easy Xcode integration
//

import SwiftUI

// MARK: - Models & Configuration

/// Represents a musical note falling in the game
struct FallingNoteModel: Identifiable {
    let id = UUID()
    let note: String        // "DO", "RE", "MI", "FA", "SOL", "LA", "SI"
    let laneIndex: Int      // Which vertical lane (0-6)
    let startDelay: Double  // Delay before animation starts (seconds)
    let duration: Double    // How long the fall animation takes (seconds)
    
    /// Get the color for this note based on musical note name (matches reference image)
    var color: Color {
        switch note.uppercased() {
        case "DO":
            return Color(red: 1.0, green: 0.45, blue: 0.5) // Coral/Pink-Red
        case "RE":
            return Color(red: 1.0, green: 0.6, blue: 0.4) // Orange
        case "MI":
            return Color(red: 1.0, green: 0.85, blue: 0.0) // Bright Yellow
        case "FA":
            return Color(red: 1.0, green: 0.95, blue: 0.3) // Light Yellow
        case "SOL":
            return Color(red: 0.9, green: 0.95, blue: 0.4) // Yellow-Green
        case "LA":
            return Color(red: 0.4, green: 0.85, blue: 0.5) // Bright Green
        case "SI":
            return Color(red: 0.4, green: 0.7, blue: 1.0) // Bright Blue
        default:
            return .gray
        }
    }
}

/// Configuration for the falling notes game
struct FallingNotesConfig {
    static let numberOfLanes = 7
    static let noteHeight: CGFloat = 42 // Smaller pill-shaped height
    static let noteCornerRadius: CGFloat = 21 // Full capsule
    static let laneSpacing: CGFloat = 8
    static let defaultFallDuration: Double = 4.0
    static let startOffsetY: CGFloat = -200
}

// MARK: - Note Block View

/// A single falling note block with pill-shape and gradient (matches reference image)
struct NoteBlockView: View {
    let note: FallingNoteModel
    let laneWidth: CGFloat
    
    var body: some View {
        ZStack {
            // Pill-shaped background with gradient
            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            note.color.opacity(0.9),
                            note.color
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: note.color.opacity(0.6), radius: 6, x: 0, y: 3)
            
            // Glossy overlay effect
            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.0)
                        ]),
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            
            // White text label
            Text(note.note.uppercased())
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .frame(
            width: min(laneWidth * 0.75, 85), // Smaller, compact width
            height: 42 // Smaller, pill-shaped height
        )
    }
}

// MARK: - Vertical Lanes View

/// Draws vertical lanes where notes fall
struct VerticalLanesView: View {
    let numberOfLanes: Int
    let laneWidth: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: FallingNotesConfig.laneSpacing) {
                ForEach(0..<numberOfLanes, id: \.self) { index in
                    VStack {
                        Spacer()
                    }
                    .frame(width: laneWidth)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.03),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.03)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        // Subtle lane separator
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 1),
                        alignment: .trailing
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Main Game View

/// Main game view with falling notes animation
struct FallingNotesGameView: View {
    let notes: [FallingNoteModel]
    
    @State private var animationStates: [UUID: Bool] = [:]
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let availableWidth = totalWidth - (CGFloat(FallingNotesConfig.numberOfLanes - 1) * FallingNotesConfig.laneSpacing)
            let laneWidth = availableWidth / CGFloat(FallingNotesConfig.numberOfLanes)
            
            ZStack {
                // Background lanes
                VerticalLanesView(
                    numberOfLanes: FallingNotesConfig.numberOfLanes,
                    laneWidth: laneWidth
                )
                
                // Falling notes
                ForEach(notes) { note in
                    NoteBlockView(note: note, laneWidth: laneWidth)
                        .position(
                            x: calculateXPosition(for: note.laneIndex, laneWidth: laneWidth),
                            y: animationStates[note.id] == true
                                ? geometry.size.height + 100  // Bottom (off-screen)
                                : FallingNotesConfig.startOffsetY  // Top (off-screen)
                        )
                        .onAppear {
                            // Start animation after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + note.startDelay) {
                                withAnimation(
                                    .linear(duration: note.duration)
                                ) {
                                    animationStates[note.id] = true
                                }
                            }
                        }
                }
            }
        }
    }
    
    /// Calculate the X position for a note in a given lane
    private func calculateXPosition(for laneIndex: Int, laneWidth: CGFloat) -> CGFloat {
        let spacing = FallingNotesConfig.laneSpacing
        return (laneWidth / 2) + (CGFloat(laneIndex) * (laneWidth + spacing))
    }
}

// MARK: - Demo View

/// Demo view with continuous falling notes animation
struct FallingNotesDemoView: View {
    @State private var noteSequence: [FallingNoteModel] = []
    @State private var animationCounter = 0
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Game title
                VStack(spacing: 8) {
                    Text("🎹 Falling Notes Piano")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Watch the notes fall!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Falling notes game area
                FallingNotesGameView(notes: noteSequence)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Piano keyboard placeholder (visual only)
                pianoKeyboardPlaceholder
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            startContinuousAnimation()
        }
    }
    
    /// Placeholder for piano keyboard at bottom
    private var pianoKeyboardPlaceholder: some View {
        HStack(spacing: 4) {
            ForEach(["DO", "RE", "MI", "FA", "SOL", "LA", "SI"], id: \.self) { note in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 70, height: 100)
                        .overlay(
                            Text(note)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    /// Start continuous falling notes animation
    private func startContinuousAnimation() {
        // Initial sequence
        generateNoteSequence()
        
        // Repeat animation every 5 seconds
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            generateNoteSequence()
        }
    }
    
    /// Generate a new sequence of falling notes
    private func generateNoteSequence() {
        let notes = ["DO", "RE", "MI", "FA", "SOL", "LA", "SI"]
        var sequence: [FallingNoteModel] = []
        
        // Create a musical pattern
        let pattern = [
            (note: "DO", lane: 0, delay: 0.0),
            (note: "MI", lane: 2, delay: 0.5),
            (note: "SOL", lane: 4, delay: 1.0),
            (note: "MI", lane: 2, delay: 1.5),
            (note: "DO", lane: 0, delay: 2.0),
            (note: "RE", lane: 1, delay: 2.5),
            (note: "FA", lane: 3, delay: 3.0),
            (note: "LA", lane: 5, delay: 3.5),
        ]
        
        for item in pattern {
            sequence.append(
                FallingNoteModel(
                    note: item.note,
                    laneIndex: item.lane,
                    startDelay: item.delay,
                    duration: 3.5
                )
            )
        }
        
        animationCounter += 1
        noteSequence = sequence
    }
}

// MARK: - Previews

#Preview("Note Blocks") {
    VStack(spacing: 16) {
        NoteBlockView(
            note: FallingNoteModel(note: "DO", laneIndex: 0, startDelay: 0, duration: 3),
            laneWidth: 80
        )
        
        NoteBlockView(
            note: FallingNoteModel(note: "RE", laneIndex: 1, startDelay: 0, duration: 3),
            laneWidth: 80
        )
        
        NoteBlockView(
            note: FallingNoteModel(note: "MI", laneIndex: 2, startDelay: 0, duration: 3),
            laneWidth: 80
        )
        
        NoteBlockView(
            note: FallingNoteModel(note: "FA", laneIndex: 3, startDelay: 0, duration: 3),
            laneWidth: 80
        )
        
        NoteBlockView(
            note: FallingNoteModel(note: "SOL", laneIndex: 4, startDelay: 0, duration: 3),
            laneWidth: 80
        )
        
        NoteBlockView(
            note: FallingNoteModel(note: "LA", laneIndex: 5, startDelay: 0, duration: 3),
            laneWidth: 80
        )
        
        NoteBlockView(
            note: FallingNoteModel(note: "SI", laneIndex: 6, startDelay: 0, duration: 3),
            laneWidth: 80
        )
    }
    .padding()
    .background(Color.black)
}

#Preview("Vertical Lanes") {
    VerticalLanesView(
        numberOfLanes: 7,
        laneWidth: 80
    )
    .background(Color.black)
    .frame(width: 600, height: 800)
}

#Preview("Game View") {
    let sampleNotes = [
        FallingNoteModel(note: "DO", laneIndex: 0, startDelay: 0.0, duration: 4.0),
        FallingNoteModel(note: "RE", laneIndex: 1, startDelay: 0.5, duration: 4.0),
        FallingNoteModel(note: "MI", laneIndex: 2, startDelay: 1.0, duration: 4.0),
        FallingNoteModel(note: "FA", laneIndex: 3, startDelay: 1.5, duration: 4.0),
        FallingNoteModel(note: "SOL", laneIndex: 4, startDelay: 2.0, duration: 4.0),
        FallingNoteModel(note: "LA", laneIndex: 5, startDelay: 2.5, duration: 4.0),
        FallingNoteModel(note: "SI", laneIndex: 6, startDelay: 3.0, duration: 4.0),
    ]
    
    return FallingNotesGameView(notes: sampleNotes)
        .background(Color.black)
        .frame(width: 600, height: 800)
}

#Preview("Demo - iPad Landscape") {
    FallingNotesDemoView()
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (6th generation)"))
        .previewInterfaceOrientation(.landscapeLeft)
}
