//
//  LevelUiState.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 23/11/2025.
//

import Foundation

struct LevelUiState {
    var isLoading: Bool = false
    var currentLevel: Level? = nil
    var unlockedLevels: [String: Bool] = [:]
    var progressPercentage: Float = 0
    var currentNoteIndex: Int = 0
    var isLevelCompleted: Bool = false
    var isFailed: Bool = false
    var wrongNoteCount: Int = 0
    var showWrongAnimation: Bool = false
    var wrongMessage: String? = nil
    var score: Int = 0
}
