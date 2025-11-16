//
//  HomeViewModel.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import Foundation
import CoreGraphics

@MainActor
final class HomeMapViewModel: ObservableObject {

    // MARK: - Levels

    @Published var levels: [Level] = LevelMockData.levels

    var lastCompletedIndex: Int {
        let completed = levels.filter { $0.state == .completed }
        guard let maxIndex = completed.map(\.index).max() else { return 0 }
        return maxIndex - 1  // convert 1-based level index to array index
    }

    var totalStars: Int {
        levels.reduce(0) { $0 + $1.earnedStars }
    }

    func shipPosition(in mapSize: CGSize) -> CGPoint {
        let index = max(0, min(lastCompletedIndex, levels.count - 1))
        let level = levels[index]
        return CGPoint(
            x: level.position.x * mapSize.width,
            y: level.position.y * mapSize.height - 40
        )
    }
}
