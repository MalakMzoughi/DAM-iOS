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
