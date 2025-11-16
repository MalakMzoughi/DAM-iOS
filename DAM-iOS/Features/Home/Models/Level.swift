//
//  Level.swift
//  DAM-iOS
//
//  Created by Malak on 14/11/2025.
//

import Foundation
import CoreGraphics

enum LevelState: String, Codable {
    case locked
    case unlocked
    case completed
}

struct Level: Identifiable, Codable {
    let id: Int                 // backend id
    let index: Int              // order on the map
    let name: String            // "Electric Meadow"
    let islandAsset: String     // island image name in Assets
    let badgeIcon: String       // small icon on the level card
    let maxStars: Int           // usually 3
    var earnedStars: Int        // 0...maxStars
    var state: LevelState

    /// Normalized position 0–1 (multiplied by map size in the view).
    let position: CGPoint
}
