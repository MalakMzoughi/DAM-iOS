//
//  UnlockedLevelsResponse.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 23/11/2025.
//

import Foundation

struct UnlockedLevelsResponse: Codable {
    let userId: String
    let levels: [UnlockedLevelItem]
}

struct UnlockedLevelItem: Identifiable, Codable {
    let id = UUID()    // local ID for SwiftUI list
    let levelId: String
    let title: String
    let theme: String
    let unlocked: Bool
    let starsUnlocked: Int
    let backgroundUrl: String?
    let bossUrl: String?
    let musicUrl: String?

    init(
        levelId: String,
        title: String,
        theme: String,
        unlocked: Bool,
        starsUnlocked: Int,
        backgroundUrl: String?,
        bossUrl: String?,
        musicUrl: String?
    ) {
        self.levelId = levelId
        self.title = title
        self.theme = theme
        self.unlocked = unlocked
        self.starsUnlocked = starsUnlocked
        self.backgroundUrl = backgroundUrl
        self.bossUrl = bossUrl
        self.musicUrl = musicUrl
    }

    enum CodingKeys: String, CodingKey {
        case levelId
        case title
        case theme
        case unlocked
        case starsUnlocked
        case backgroundUrl
        case bossUrl
        case musicUrl
    }
}
