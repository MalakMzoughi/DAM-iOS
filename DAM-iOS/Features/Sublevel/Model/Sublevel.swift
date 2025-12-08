//
//  Sublevel.swift
//  DAM-iOS
//
//  Minimal model for backend sublevels
//

import Foundation

struct Sublevel: Identifiable, Codable {
    let id: String // _id
    let levelId: String
    let index: Int
    let difficulty: Int
    let notes: [String]
    let noteDurations: [String]?
    let maxStars: Int
    let requiredStars: Int
    // Optional runtime fields provided by backend about progress/unlock state
    let unlocked: Bool?
    let starsEarned: Int?
    let completed: Bool?
    let totalStars: Int?
    let previousCompleted: Bool?
    let trackName: String?
    let backgroundUrl: String?
    let bossUrl: String?
    let heroUrl: String?
    let trackUrl: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case levelId
        case index
        case difficulty
        case notes
        case maxStars
        case requiredStars
        case noteDurations
        case unlocked
        case starsEarned
        case stars
        case completed
        case totalStars
        case previousCompleted
        case trackName
        case backgroundUrl
        case bossUrl
        case heroUrl
        case trackUrl
    }

    init(id: String,
         levelId: String,
         index: Int,
         difficulty: Int,
         notes: [String],
         noteDurations: [String]? = nil,
         maxStars: Int,
         requiredStars: Int,
         unlocked: Bool? = nil,
         starsEarned: Int? = nil,
         completed: Bool? = nil,
         totalStars: Int? = nil,
         previousCompleted: Bool? = nil,
         trackName: String? = nil,
         backgroundUrl: String? = nil,
         bossUrl: String? = nil,
         heroUrl: String? = nil,
         trackUrl: String? = nil) {
        self.id = id
        self.levelId = levelId
        self.index = index
        self.difficulty = difficulty
        self.notes = notes
        self.noteDurations = noteDurations
        self.maxStars = maxStars
        self.requiredStars = requiredStars
        self.unlocked = unlocked
        self.starsEarned = starsEarned
        self.completed = completed
        self.totalStars = totalStars
        self.previousCompleted = previousCompleted
        self.trackName = trackName
        self.backgroundUrl = backgroundUrl
        self.bossUrl = bossUrl
        self.heroUrl = heroUrl
        self.trackUrl = trackUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        levelId = try container.decode(String.self, forKey: .levelId)
        index = try container.decode(Int.self, forKey: .index)
        difficulty = try container.decode(Int.self, forKey: .difficulty)
        notes = try container.decode([String].self, forKey: .notes)
        maxStars = try container.decode(Int.self, forKey: .maxStars)
        requiredStars = try container.decode(Int.self, forKey: .requiredStars)
        noteDurations = try container.decodeIfPresent([String].self, forKey: .noteDurations)
        unlocked = try container.decodeIfPresent(Bool.self, forKey: .unlocked)
        let starsDirect = try container.decodeIfPresent(Int.self, forKey: .starsEarned)
        let starsFallback = try container.decodeIfPresent(Int.self, forKey: .stars)
        starsEarned = starsDirect ?? starsFallback
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed)
        totalStars = try container.decodeIfPresent(Int.self, forKey: .totalStars)
        previousCompleted = try container.decodeIfPresent(Bool.self, forKey: .previousCompleted)
        trackName = try container.decodeIfPresent(String.self, forKey: .trackName)
        backgroundUrl = try container.decodeIfPresent(String.self, forKey: .backgroundUrl)
        bossUrl = try container.decodeIfPresent(String.self, forKey: .bossUrl)
        heroUrl = try container.decodeIfPresent(String.self, forKey: .heroUrl)
        trackUrl = try container.decodeIfPresent(String.self, forKey: .trackUrl)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(levelId, forKey: .levelId)
        try container.encode(index, forKey: .index)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(notes, forKey: .notes)
        try container.encode(maxStars, forKey: .maxStars)
        try container.encode(requiredStars, forKey: .requiredStars)
        try container.encodeIfPresent(noteDurations, forKey: .noteDurations)
        try container.encodeIfPresent(unlocked, forKey: .unlocked)
        try container.encodeIfPresent(starsEarned, forKey: .starsEarned)
        try container.encodeIfPresent(starsEarned, forKey: .stars)
        try container.encodeIfPresent(completed, forKey: .completed)
        try container.encodeIfPresent(totalStars, forKey: .totalStars)
        try container.encodeIfPresent(previousCompleted, forKey: .previousCompleted)
        try container.encodeIfPresent(trackName, forKey: .trackName)
        try container.encodeIfPresent(backgroundUrl, forKey: .backgroundUrl)
        try container.encodeIfPresent(bossUrl, forKey: .bossUrl)
        try container.encodeIfPresent(heroUrl, forKey: .heroUrl)
        try container.encodeIfPresent(trackUrl, forKey: .trackUrl)
    }
}
