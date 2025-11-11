//
//  LevelModels.swift
//  DAM-iOS
//
//  Created by iMac on 10/11/2025.
//

import SwiftUI

// MARK: - Player

struct PlayerProfile: Identifiable, Codable {
    let id: String
    var name: String
    var levelLabel: String
    var starsOwned: Int
    var starsTotal: Int

    // Convenience accessors if you need them
    var totalStars: Int { starsOwned }
    var maxStars: Int { starsTotal }
}

extension PlayerProfile {
    static let mock = PlayerProfile(
        id: "u1",
        name: "Player",
        levelLabel: "Level 1 · Beginner",
        starsOwned: 0,
        starsTotal: 24
    )
}

// MARK: - Level

struct LevelNode: Identifiable, Codable {
    let id: String

    let index: Int
    let title: String
    let subtitle: String
    var stars: Int
    let lane: Int

    var number: Int { index }
    var world: String { subtitle }
}

extension Array where Element == LevelNode {
    static let mock: [LevelNode] = [
        .init(id: "l1", index: 1, title: "Basic Keys",   subtitle: "Pirate Ship", stars: 0, lane: 0),
        .init(id: "l2", index: 2, title: "Left Hand",    subtitle: "First Mate",  stars: 0, lane: 1),
        .init(id: "l3", index: 3, title: "Right Hand",   subtitle: "Helmsman",    stars: 0, lane: 0),
        .init(id: "l4", index: 4, title: "Both Hands",   subtitle: "Captain",     stars: 0, lane: 1),
    ]
}
