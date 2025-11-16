//
//  ReadyPlayerMeModel.swift
//  DAM-iOS
//
//  Ready Player Me integration models and configuration
//

import Foundation

// MARK: - Ready Player Me Avatar Model
struct ReadyPlayerMeAvatar: Codable, Identifiable {
    let id: String
    var userId: String?
    var avatarUrl: String
    var glbUrl: String?
    var thumbnailUrl: String?
    var avatarName: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        avatarUrl: String,
        glbUrl: String? = nil,
        thumbnailUrl: String? = nil,
        avatarName: String = "My Avatar",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.avatarUrl = avatarUrl
        self.glbUrl = glbUrl
        self.thumbnailUrl = thumbnailUrl
        self.avatarName = avatarName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Ready Player Me Configuration
struct ReadyPlayerMeConfig {
    static let subdomain = "pianokids"  // Your subdomain
    static let appId = "69179e3a771c8dd1a3aedb66"  // Your App ID
    static let baseURL = "https://\(subdomain).readyplayer.me"
    
    // Avatar creator URL with configuration
    static func getAvatarCreatorURL(quickStart: Bool = false, existingAvatarUrl: String? = nil) -> String {
        var params: [String] = []
        
        // App ID is required for saving avatars
        params.append("appId=\(appId)")
        
        // Enable frame API for communication
        params.append("frameApi")
        
        // Body type selection (fullbody as per your settings)
        params.append("bodyType=fullbody")
        
        // Quick start skips intro
        if quickStart {
            params.append("quickStart=true")
        }
        
        // If editing existing avatar, pass the avatar URL
        if let existingUrl = existingAvatarUrl, !existingUrl.isEmpty {
            // Extract avatar ID from URL
            let avatarId = extractAvatarId(from: existingUrl)
            if !avatarId.isEmpty && avatarId != existingUrl {
                // Pass the avatar URL to load existing avatar (URL encode it)
                if let encodedUrl = existingUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    params.append("avatarUrl=\(encodedUrl)")
                }
            }
        }
        
        // Clear cache for testing
        params.append("clearCache")
        
        let paramString = params.joined(separator: "&")
        let finalURL = "\(baseURL)/avatar?\(paramString)"
        print("🔗 Ready Player Me URL: \(finalURL)")
        return finalURL
    }
    
    // Get high-quality render URL
    static func getRenderURL(avatarUrl: String, scene: String = "fullbody-portrait-v1") -> String {
        let avatarId = extractAvatarId(from: avatarUrl)
        return "https://models.readyplayer.me/\(avatarId).png?scene=\(scene)"
    }
    
    // Extract avatar ID from URL
    static func extractAvatarId(from url: String) -> String {
        // Extract the avatar ID (24-character hex string)
        if let range = url.range(of: "[0-9a-f]{24}", options: .regularExpression) {
            return String(url[range])
        }
        
        // If no match, try to extract from URL path
        if let url = URL(string: url),
           let lastComponent = url.pathComponents.last {
            // Remove .glb or .png extension
            return lastComponent.replacingOccurrences(of: ".glb", with: "")
                .replacingOccurrences(of: ".png", with: "")
        }
        
        return url
    }
}
