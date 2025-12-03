//
//  AvatarModels.swift
//  DAM-iOS
//
//  Avatar data models for AI generation and customization
//

import Foundation

// MARK: - Main Avatar Model
struct Avatar: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let name: String
    let customization: AvatarCustomization?
    let isActive: Bool
    let expression: String?
    let avatarImageUrl: String?
    let energy: Int?
    let experience: Int?
    let level: Int?
    let state: String?
    let outfits: AvatarOutfits?
    let createdAt: String
    let updatedAt: String
    let readyPlayerMeId: String?
    let readyPlayerMeAvatarUrl: String?
    let readyPlayerMeGlbUrl: String?
    let readyPlayerMeThumbnailUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case name
        case customization
        case isActive
        case expression
        case avatarImageUrl
        case energy
        case experience
        case level
        case state
        case outfits
        case createdAt
        case updatedAt
        case readyPlayerMeId
        case readyPlayerMeAvatarUrl
        case readyPlayerMeGlbUrl
        case readyPlayerMeThumbnailUrl
    }
}

// MARK: - Avatar Customization
struct AvatarCustomization: Codable, Equatable {
    let style: String
    let bodyType: String
    let skinTone: String
    let hairstyle: String
    let hairColor: String
    let eyeStyle: String
    let eyeColor: String
    let clothingType: String?
    let clothingColor: String?
    let accessories: [String]?
}

// MARK: - Avatar Outfits
struct AvatarOutfits: Codable, Equatable {
    let unlocked: [String]
    let equipped: String
}

// MARK: - Create Avatar DTO
struct CreateAvatarDto: Codable {
    let name: String
    let customization: CreateAvatarCustomizationDto
    let avatarImageUrl: String?
}

struct CreateAvatarCustomizationDto: Codable {
    let style: String
    let bodyType: String
    let skinTone: String
    let hairstyle: String
    let hairColor: String
    let eyeStyle: String
    let eyeColor: String
    let clothingType: String?
    let clothingColor: String?
    let accessories: [String]?
}

// MARK: - Create Avatar Request (for ReadyPlayerMe integration)
struct CreateAvatarRequest: Codable {
    let name: String
    let customization: CreateAvatarCustomizationDto?
    let avatarImageUrl: String?
    let readyPlayerMeId: String?
    let readyPlayerMeAvatarUrl: String?
    let readyPlayerMeGlbUrl: String?
    let readyPlayerMeThumbnailUrl: String?
    
    init(name: String,
         customization: CreateAvatarCustomizationDto? = nil,
         avatarImageUrl: String? = nil,
         readyPlayerMeId: String? = nil,
         readyPlayerMeAvatarUrl: String? = nil,
         readyPlayerMeGlbUrl: String? = nil,
         readyPlayerMeThumbnailUrl: String? = nil) {
        self.name = name
        self.customization = customization
        self.avatarImageUrl = avatarImageUrl
        self.readyPlayerMeId = readyPlayerMeId
        self.readyPlayerMeAvatarUrl = readyPlayerMeAvatarUrl
        self.readyPlayerMeGlbUrl = readyPlayerMeGlbUrl
        self.readyPlayerMeThumbnailUrl = readyPlayerMeThumbnailUrl
    }
}

// MARK: - Update Avatar DTO
struct UpdateAvatarDto: Codable {
    let name: String?
    let customization: CreateAvatarCustomizationDto?
    let expression: String?
    let energy: Int?
    let state: String?
    let isActive: Bool?
    let equippedOutfit: String?
    let avatarImageUrl: String?
    let readyPlayerMeId: String?
    let readyPlayerMeAvatarUrl: String?
    let readyPlayerMeGlbUrl: String?
    let readyPlayerMeThumbnailUrl: String?
}

// Type alias for consistency with API layer
typealias UpdateAvatarRequest = UpdateAvatarDto

// MARK: - Avatar Stats
struct AvatarStats: Codable {
    let level: Int
    let experience: Int
    let energy: Int
    let outfitsUnlocked: Int
}

// MARK: - Gemini AI Avatar Generation
struct GenerateAvatarFromPromptDto: Codable {
    let prompt: String
    let name: String
    let style: String
    
    init(prompt: String, name: String, style: String = "cartoon") {
        self.prompt = prompt
        self.name = name
        self.style = style
    }
}

struct AvatarGenerationResponse: Codable, Equatable {
    let name: String
    let description: String
    let aiGeneratedDescription: String?
    let suggestedAttributes: SuggestedAttributes
    let avatarImageUrl: String?
    let generationSource: String
    let previewData: AnyCodable // Opaque preview data to send back when saving
}

struct SaveAIAvatarResponse: Codable {
    let avatarId: String
    let name: String
    let avatarImageUrl: String?
    let aiGeneratedDescription: String?
    let generationSource: String
    let avatar: Avatar
}

struct SuggestedAttributes: Codable, Equatable {
    let bodyType: String
    let skinTone: String
    let hairstyle: String
    let hairColor: String
    let eyeStyle: String
    let eyeColor: String
    let clothingType: String
    let clothingColor: String
    let accessories: [String]
}

struct SaveAIAvatarRequest: Codable {
    let previewData: AnyCodable
    let name: String?
    
    init(previewData: AnyCodable, name: String? = nil) {
        self.previewData = previewData
        self.name = name
    }
}

// MARK: - Helper for Any Codable
struct AnyCodable: Codable, Equatable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
    
    // Equatable conformance
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Convert both values to JSON data and compare
        // This is a simple equality check that works for most cases
        let lhsData = try? JSONSerialization.data(withJSONObject: lhs.value, options: .sortedKeys)
        let rhsData = try? JSONSerialization.data(withJSONObject: rhs.value, options: .sortedKeys)
        return lhsData == rhsData
    }
}

// MARK: - Delete Avatar Response
struct DeleteAvatarResponse: Codable {
    let message: String
}
