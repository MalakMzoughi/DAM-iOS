//
//  AvatarService.swift
//  DAM-iOS
//
//  Avatar API service for CRUD operations and AI generation
//

import Foundation

class AvatarService {
    
    static let shared = AvatarService()
    private init() {}
    
    private let baseURL = "http://192.168.100.52:3000/api/avatars"
    
    // MARK: - Helper Methods
    
    private func getAuthHeaders() -> (String, String)? {
        guard let authToken = UserDefaults.standard.string(forKey: "authToken"),
              let providerId = UserDefaults.standard.string(forKey: "providerId") else {
            print("❌ AvatarService: Missing auth credentials")
            return nil
        }
        return (authToken, providerId)
    }
    
    private func createRequest(url: URL, method: String, body: Data? = nil) throws -> URLRequest {
        guard let (authToken, providerId) = getAuthHeaders() else {
            throw NSError(domain: "AvatarService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authToken, forHTTPHeaderField: "X-Auth-Token")
        request.setValue(providerId, forHTTPHeaderField: "X-Provider-ID")
        request.httpBody = body
        
        return request
    }
    
    // MARK: - Avatar CRUD Operations
    
    /// Create a new avatar
    func createAvatar(dto: CreateAvatarDto) async throws -> Avatar {
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let body = try JSONEncoder().encode(dto)
        let request = try createRequest(url: url, method: "POST", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create avatar"])
        }
        
        let avatar = try JSONDecoder().decode(Avatar.self, from: data)
        print("✅ Avatar created: \(avatar.name)")
        return avatar
    }
    
    /// Get all avatars for user
    func getUserAvatars() async throws -> [Avatar] {
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get avatars"])
        }
        
        let avatars = try JSONDecoder().decode([Avatar].self, from: data)
        print("✅ Fetched \(avatars.count) avatars")
        return avatars
    }
    
    /// Get active avatar
    func getActiveAvatar() async throws -> Avatar {
        guard let url = URL(string: "\(baseURL)/active") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get active avatar"])
        }
        
        let avatar = try JSONDecoder().decode(Avatar.self, from: data)
        print("✅ Active avatar: \(avatar.name)")
        return avatar
    }
    
    /// Get avatar by ID
    func getAvatar(avatarId: String) async throws -> Avatar {
        guard let url = URL(string: "\(baseURL)/\(avatarId)") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get avatar"])
        }
        
        let avatar = try JSONDecoder().decode(Avatar.self, from: data)
        return avatar
    }
    
    /// Update avatar
    func updateAvatar(avatarId: String, dto: UpdateAvatarDto) async throws -> Avatar {
        guard let url = URL(string: "\(baseURL)/\(avatarId)") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let body = try JSONEncoder().encode(dto)
        let request = try createRequest(url: url, method: "PUT", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update avatar"])
        }
        
        let avatar = try JSONDecoder().decode(Avatar.self, from: data)
        print("✅ Avatar updated: \(avatar.name)")
        return avatar
    }
    
    /// Set active avatar
    func setActiveAvatar(avatarId: String) async throws -> Avatar {
        guard let url = URL(string: "\(baseURL)/\(avatarId)/activate") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let request = try createRequest(url: url, method: "POST")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: "Failed to set active avatar"])
        }
        
        let avatar = try JSONDecoder().decode(Avatar.self, from: data)
        print("✅ Avatar activated: \(avatar.name)")
        return avatar
    }
    
    /// Delete avatar
    func deleteAvatar(avatarId: String) async throws -> DeleteAvatarResponse {
        guard let url = URL(string: "\(baseURL)/\(avatarId)") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let request = try createRequest(url: url, method: "DELETE")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: "Failed to delete avatar"])
        }
        
        let result = try JSONDecoder().decode(DeleteAvatarResponse.self, from: data)
        print("✅ Avatar deleted")
        return result
    }
    
    // MARK: - Avatar Gameplay Operations
    
    /// Update avatar expression
    func updateExpression(avatarId: String, expression: String) async throws -> Avatar {
        guard let url = URL(string: "\(baseURL)/\(avatarId)/expression") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let body = try JSONSerialization.data(withJSONObject: ["expression": expression])
        let request = try createRequest(url: url, method: "PUT", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return try JSONDecoder().decode(Avatar.self, from: data)
    }
    
    /// Update avatar energy
    func updateEnergy(avatarId: String, energyChange: Int) async throws -> Avatar {
        guard let url = URL(string: "\(baseURL)/\(avatarId)/energy") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let body = try JSONSerialization.data(withJSONObject: ["energyChange": energyChange])
        let request = try createRequest(url: url, method: "PUT", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return try JSONDecoder().decode(Avatar.self, from: data)
    }
    
    /// Add experience to avatar
    func addExperience(avatarId: String, xpGain: Int) async throws -> Avatar {
        guard let url = URL(string: "\(baseURL)/\(avatarId)/experience") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let body = try JSONSerialization.data(withJSONObject: ["xpGain": xpGain])
        let request = try createRequest(url: url, method: "POST", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return try JSONDecoder().decode(Avatar.self, from: data)
    }
    
    /// Get avatar stats
    func getAvatarStats(avatarId: String) async throws -> AvatarStats {
        guard let url = URL(string: "\(baseURL)/\(avatarId)/stats") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let request = try createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return try JSONDecoder().decode(AvatarStats.self, from: data)
    }
    
    /// Equip outfit
    func equipOutfit(avatarId: String, outfitId: String) async throws -> Avatar {
        guard let url = URL(string: "\(baseURL)/\(avatarId)/outfits/\(outfitId)/equip") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let request = try createRequest(url: url, method: "POST")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return try JSONDecoder().decode(Avatar.self, from: data)
    }
    
    /// Unlock outfit
    func unlockOutfit(avatarId: String, outfitId: String) async throws -> Avatar {
        guard let url = URL(string: "\(baseURL)/\(avatarId)/outfits/\(outfitId)/unlock") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let request = try createRequest(url: url, method: "POST")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return try JSONDecoder().decode(Avatar.self, from: data)
    }
    
    // MARK: - Gemini AI Avatar Generation
    
    /// Generate avatar from AI prompt (preview only, not saved)
    func generateAvatarFromPrompt(dto: GenerateAvatarFromPromptDto) async throws -> AvatarGenerationResponse {
        guard let url = URL(string: "\(baseURL)/generate-from-prompt") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let body = try JSONEncoder().encode(dto)
        let request = try createRequest(url: url, method: "POST", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ AI generation failed: \(errorBody)")
            throw NSError(domain: "AvatarService", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: "Failed to generate avatar with AI"])
        }
        
        let result = try JSONDecoder().decode(AvatarGenerationResponse.self, from: data)
        print("✅ AI avatar generated: \(result.name)")
        return result
    }
    
    /// Save AI-generated avatar after user approves
    func saveAIAvatar(previewData: AnyCodable, name: String? = nil) async throws -> SaveAIAvatarResponse {
        guard let url = URL(string: "\(baseURL)/save-ai-avatar") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        print("📤 AvatarService: Saving AI avatar with name: '\(name ?? "nil")'")
        
        let requestBody = SaveAIAvatarRequest(previewData: previewData, name: name)
        let body = try JSONEncoder().encode(requestBody)
        
        // Log the request body to verify name is included
        if let jsonString = String(data: body, encoding: .utf8) {
            print("📦 Request body: \(jsonString)")
        }
        
        let request = try createRequest(url: url, method: "POST", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("❌ Failed to save AI avatar. Status: \(statusCode), Body: \(errorBody)")
            throw NSError(domain: "AvatarService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to save AI avatar"])
        }
        
        let result = try JSONDecoder().decode(SaveAIAvatarResponse.self, from: data)
        print("✅ AI avatar saved successfully: \(result.name)")
        return result
    }
}
