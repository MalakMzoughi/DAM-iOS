//
//  Level.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 23/11/2025.
//

import Foundation

struct Level: Identifiable, Codable {
    let id: String                      // _id
    let order: Int
    let title: String
    let theme: String
    let story: String
    let expectedNotes: [String]
    let difficulty: Int
    let backgroundUrl: String?
    let backgroundAssetKey: String?
    let bossUrl: String?
    let musicUrl: String?
    let previewAudioUrl: String?
    let previewDuration: Int?
    let autoPlayPreview: Bool?
    let starsUnlocked: Int
    let mapPosition: MapPosition
    let islandImageUrl: String
    let nextLevelId: String?
    let colorTheme: String?

    // Custom decoding because backend sends "_id"
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case order
        case title
        case theme
        case story
        case expectedNotes
        case difficulty
        case backgroundUrl
        case backgroundAssetKey
        case bossUrl
        case musicUrl
        case previewAudioUrl
        case previewDuration
        case autoPlayPreview
        case starsUnlocked
        case mapPosition
        case islandImageUrl
        case nextLevelId
        case colorTheme
    }
}

struct MapPosition: Codable {
    let x: Float
    let y: Float
}
