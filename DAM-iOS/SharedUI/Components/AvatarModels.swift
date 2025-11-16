//
//  AvatarModels.swift
//  DAM-iOS
//
//  Avatar data models with Ready Player Me support
//

import Foundation

// MARK: - Avatar Customization
struct AvatarCustomization: Codable, Equatable {
    var style: String
    var bodyType: String
    var skinTone: String
    var hairstyle: String
    var hairColor: String
    var eyeStyle: String
    var eyeColor: String
    var clothingType: String?
    var clothingColor: String?
    var accessories: [String]
    
    init(
        style: String = "realistic",
        bodyType: String = "fullbody",
        skinTone: String = "medium",
        hairstyle: String = "short",
        hairColor: String = "brown",
        eyeStyle: String = "round",
        eyeColor: String = "brown",
        clothingType: String? = "casual",
        clothingColor: String? = "blue",
        accessories: [String] = []
    ) {
        self.style = style
        self.bodyType = bodyType
        self.skinTone = skinTone
        self.hairstyle = hairstyle
        self.hairColor = hairColor
        self.eyeStyle = eyeStyle
        self.eyeColor = eyeColor
        self.clothingType = clothingType
        self.clothingColor = clothingColor
        self.accessories = accessories
    }
}

// MARK: - Avatar Outfits
struct AvatarOutfits: Codable, Equatable {
    var unlocked: [String]
    var equipped: String
    
    init(unlocked: [String] = ["outfit_default"], equipped: String = "outfit_default") {
        self.unlocked = unlocked
        self.equipped = equipped
    }
}

// MARK: - Avatar Model
struct Avatar: Identifiable, Codable, Equatable {
    let id: String
    var userId: String?
    var name: String
    var customization: AvatarCustomization?
    var isActive: Bool
    var expression: String
    var avatarImageUrl: String?
    
    // Ready Player Me specific fields
    var readyPlayerMeId: String?
    var readyPlayerMeAvatarUrl: String?
    var readyPlayerMeGlbUrl: String?
    var readyPlayerMeThumbnailUrl: String?
    var isReadyPlayerMe: Bool?
    
    var energy: Int
    var experience: Int
    var level: Int
    var state: String
    var outfits: AvatarOutfits
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case name
        case customization
        case isActive
        case expression
        case avatarImageUrl
        case readyPlayerMeId
        case readyPlayerMeAvatarUrl
        case readyPlayerMeGlbUrl
        case readyPlayerMeThumbnailUrl
        case isReadyPlayerMe
        case energy
        case experience
        case level
        case state
        case outfits
    }
    
    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        name: String = "My Avatar",
        customization: AvatarCustomization? = nil,
        isActive: Bool = true,
        expression: String = "happy",
        avatarImageUrl: String? = nil,
        readyPlayerMeId: String? = nil,
        readyPlayerMeAvatarUrl: String? = nil,
        readyPlayerMeGlbUrl: String? = nil,
        readyPlayerMeThumbnailUrl: String? = nil,
        isReadyPlayerMe: Bool? = nil,
        energy: Int = 100,
        experience: Int = 0,
        level: Int = 1,
        state: String = "idle",
        outfits: AvatarOutfits = AvatarOutfits()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.customization = customization
        self.isActive = isActive
        self.expression = expression
        self.avatarImageUrl = avatarImageUrl
        self.readyPlayerMeId = readyPlayerMeId
        self.readyPlayerMeAvatarUrl = readyPlayerMeAvatarUrl
        self.readyPlayerMeGlbUrl = readyPlayerMeGlbUrl
        self.readyPlayerMeThumbnailUrl = readyPlayerMeThumbnailUrl
        self.isReadyPlayerMe = isReadyPlayerMe
        self.energy = energy
        self.experience = experience
        self.level = level
        self.state = state
        self.outfits = outfits
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        customization = try container.decodeIfPresent(AvatarCustomization.self, forKey: .customization)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
        expression = try container.decodeIfPresent(String.self, forKey: .expression) ?? "happy"
        avatarImageUrl = try container.decodeIfPresent(String.self, forKey: .avatarImageUrl)
        readyPlayerMeId = try container.decodeIfPresent(String.self, forKey: .readyPlayerMeId)
        readyPlayerMeAvatarUrl = try container.decodeIfPresent(String.self, forKey: .readyPlayerMeAvatarUrl)
        readyPlayerMeGlbUrl = try container.decodeIfPresent(String.self, forKey: .readyPlayerMeGlbUrl)
        readyPlayerMeThumbnailUrl = try container.decodeIfPresent(String.self, forKey: .readyPlayerMeThumbnailUrl)
        isReadyPlayerMe = try container.decodeIfPresent(Bool.self, forKey: .isReadyPlayerMe)
        energy = try container.decodeIfPresent(Int.self, forKey: .energy) ?? 100
        experience = try container.decodeIfPresent(Int.self, forKey: .experience) ?? 0
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
        state = try container.decodeIfPresent(String.self, forKey: .state) ?? "idle"
        outfits = try container.decodeIfPresent(AvatarOutfits.self, forKey: .outfits) ?? AvatarOutfits()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(customization, forKey: .customization)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(expression, forKey: .expression)
        try container.encodeIfPresent(avatarImageUrl, forKey: .avatarImageUrl)
        try container.encodeIfPresent(readyPlayerMeId, forKey: .readyPlayerMeId)
        try container.encodeIfPresent(readyPlayerMeAvatarUrl, forKey: .readyPlayerMeAvatarUrl)
        try container.encodeIfPresent(readyPlayerMeGlbUrl, forKey: .readyPlayerMeGlbUrl)
        try container.encodeIfPresent(readyPlayerMeThumbnailUrl, forKey: .readyPlayerMeThumbnailUrl)
        try container.encodeIfPresent(isReadyPlayerMe, forKey: .isReadyPlayerMe)
        try container.encode(energy, forKey: .energy)
        try container.encode(experience, forKey: .experience)
        try container.encode(level, forKey: .level)
        try container.encode(state, forKey: .state)
        try container.encode(outfits, forKey: .outfits)
    }
}

// MARK: - Create Avatar Request
struct CreateAvatarRequest: Codable {
    let name: String
    let customization: AvatarCustomization?
    var avatarImageUrl: String?
    var readyPlayerMeId: String?
    var readyPlayerMeAvatarUrl: String?
    var readyPlayerMeGlbUrl: String?
    var readyPlayerMeThumbnailUrl: String?
    
    init(
        name: String,
        customization: AvatarCustomization? = nil,
        avatarImageUrl: String? = nil,
        readyPlayerMeId: String? = nil,
        readyPlayerMeAvatarUrl: String? = nil,
        readyPlayerMeGlbUrl: String? = nil,
        readyPlayerMeThumbnailUrl: String? = nil
    ) {
        self.name = name
        self.customization = customization
        self.avatarImageUrl = avatarImageUrl
        self.readyPlayerMeId = readyPlayerMeId
        self.readyPlayerMeAvatarUrl = readyPlayerMeAvatarUrl
        self.readyPlayerMeGlbUrl = readyPlayerMeGlbUrl
        self.readyPlayerMeThumbnailUrl = readyPlayerMeThumbnailUrl
    }
}

// MARK: - Update Avatar Request
struct UpdateAvatarRequest: Codable {
    var name: String?
    var customization: AvatarCustomization?
    var expression: String?
    var energy: Int?
    var state: String?
    var isActive: Bool?
    var avatarImageUrl: String?
    var readyPlayerMeId: String?
    var readyPlayerMeAvatarUrl: String?
    var readyPlayerMeGlbUrl: String?
    var readyPlayerMeThumbnailUrl: String?
}
