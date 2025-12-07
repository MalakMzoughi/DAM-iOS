//
//  FallingNote.swift
//  Falling Notes System
//
//  Created on 2025-12-06.
//

import SwiftUI

/// Represents a single falling note in the game
struct FallingNote: Identifiable {
    let id = UUID()
    let note: MusicNote
    let lane: Int // 0-6 for DO, RE, MI, FA, SOL, LA, SI
    var yPosition: CGFloat
    let speed: CGFloat
    let targetTime: TimeInterval
    
    init(note: MusicNote, lane: Int, speed: CGFloat = 200, targetTime: TimeInterval) {
        self.note = note
        self.lane = lane
        self.yPosition = -200 // Start off-screen at top
        self.speed = speed
        self.targetTime = targetTime
    }
}

/// Music note representation
enum MusicNote: String, CaseIterable {
    case DO = "DO"
    case RE = "RE"
    case MI = "MI"
    case FA = "FA"
    case SOL = "SOL"
    case LA = "LA"
    case SI = "SI"
    
    var displayName: String {
        return self.rawValue
    }
    
    var color: Color {
        switch self {
        case .DO:
            return Color(red: 1.0, green: 0.2, blue: 0.2) // Bright Red
        case .RE:
            return Color(red: 1.0, green: 0.5, blue: 0.0) // Bright Orange
        case .MI:
            return Color(red: 1.0, green: 0.9, blue: 0.0) // Bright Yellow
        case .FA:
            return Color(red: 0.2, green: 1.0, blue: 0.2) // Bright Green
        case .SOL:
            return Color(red: 0.2, green: 0.6, blue: 1.0) // Bright Blue
        case .LA:
            return Color(red: 0.6, green: 0.2, blue: 1.0) // Bright Purple
        case .SI:
            return Color(red: 1.0, green: 0.2, blue: 0.8) // Bright Pink
        }
    }
    
    var lane: Int {
        switch self {
        case .DO: return 0
        case .RE: return 1
        case .MI: return 2
        case .FA: return 3
        case .SOL: return 4
        case .LA: return 5
        case .SI: return 6
        }
    }
}
