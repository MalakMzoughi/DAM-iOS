//
//  LevelSelectionViewModel.swift
//  DAM-iOS
//
//  Updated to work with coordinator pattern
//

import Foundation
import Combine

// MARK: - Play Mode Enum
enum PlayMode {
    case appPiano
    case realPiano
}

@MainActor
final class LevelSelectionViewModel: ObservableObject {

    @Published var currentLevel: Level
    @Published var selectedPlayMode: PlayMode? = nil
    @Published var showAvatarSelection = false
    @Published var showPianoView = false

    init(level: Level) {
        self.currentLevel = level
    }

    func selectPlayMode(_ mode: PlayMode) {
        selectedPlayMode = mode

        switch mode {
        case .appPiano:
            // This is now handled by the parent coordinator via callback
            // But we keep this for any internal state management
            print("✅ App Piano selected")

        case .realPiano:
            print("⚠️ Real Piano mode coming soon…")
        }
    }

    func resetSelection() {
        selectedPlayMode = nil
        showAvatarSelection = false
        showPianoView = false
    }
}
