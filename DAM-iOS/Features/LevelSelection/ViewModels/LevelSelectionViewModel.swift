//
//  LevelSelectionViewModel.swift
//  DAM-iOS
//
//  Updated to work with coordinator pattern
//

import Foundation
@MainActor
final class LevelSelectionViewModel: ObservableObject {
    @Published var currentLevel: Level

    init(level: Level) {
        self.currentLevel = level
    }
}
