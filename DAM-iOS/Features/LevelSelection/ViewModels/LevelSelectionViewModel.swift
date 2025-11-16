//
//  LevelSelectionViewModel.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 12/11/2025.
//

import Foundation
import Combine

// MARK: - Play Mode Enum
enum PlayMode {
    case appPiano
    case realPiano
}

// MARK: - Level Selection ViewModel
class LevelSelectionViewModel: ObservableObject {
    // Published properties for UI binding
    @Published var currentLevel: Level
    @Published var selectedPlayMode: PlayMode?
    @Published var showAvatarSelection = false
    @Published var showPianoView = false
    
    init(level: Level) {
        self.currentLevel = level
    }
    
    // MARK: - Methods
    func selectPlayMode(_ mode: PlayMode) {
        selectedPlayMode = mode
        
        // For now, only App Piano is implemented
        if mode == .appPiano {
            // Skip avatar selection - go directly to piano with first assistant avatar
            showPianoView = true
        } else {
            // Real Piano feature coming soon
            print("Real Piano feature will be implemented in next phase")
        }
    }
    
    func resetSelection() {
        selectedPlayMode = nil
        showAvatarSelection = false
        showPianoView = false
    }
}

