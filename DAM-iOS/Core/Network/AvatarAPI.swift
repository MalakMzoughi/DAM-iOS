//
//  AvatarAPI.swift
//  DAM-iOS
//
//  API client for avatar operations
//

import Foundation

enum AvatarAPIError: LocalizedError {
    case endpointNotImplemented
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .endpointNotImplemented:
            return "Avatar feature is not yet available on the server. Please try again later."
        case .serverError(let message):
            return message
        }
    }
}

enum AvatarAPI {
    // Helper to set HMAC auth headers
    private static func setHMACHeaders(_ req: inout URLRequest, authToken: String, providerId: String) {
        req.setValue(providerId, forHTTPHeaderField: "X-Provider-ID")
        req.setValue(authToken, forHTTPHeaderField: "X-Auth-Token")
    }
    
    // Base URL - use API.base from existing API structure
    private static var baseURL: URL {
        return API.base
    }
    
    // Create avatar for user (logged in) or guest
    static func createAvatar(_ request: CreateAvatarRequest, authToken: String, providerId: String) async throws -> Avatar {
        var req = URLRequest(url: baseURL.appendingPathComponent("api/avatars"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        setHMACHeaders(&req, authToken: authToken, providerId: providerId)
        
        req.httpBody = try JSONEncoder().encode(request)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Handle 404 gracefully - endpoint might not be implemented yet
        if http.statusCode == 404 {
            print("ℹ️ Avatar creation endpoint not found (404)")
            throw AvatarAPIError.endpointNotImplemented
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "No body"
            print("❌ Avatar creation failed (\(resp)): \(bodyText)")
            throw AvatarAPIError.serverError("Failed to create avatar: \(bodyText)")
        }
        
        let avatar = try JSONDecoder().decode(Avatar.self, from: data)
        print("✅ Avatar created:", avatar.name)
        return avatar
    }
    
    // Get user's avatars
    static func getUserAvatars(authToken: String, providerId: String) async throws -> [Avatar] {
        var req = URLRequest(url: baseURL.appendingPathComponent("api/avatars"))
        req.httpMethod = "GET"
        setHMACHeaders(&req, authToken: authToken, providerId: providerId)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Handle 404 gracefully - endpoint might not be implemented yet
        if http.statusCode == 404 {
            print("ℹ️ Avatars endpoint not found (404) - returning empty array")
            return []
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "No body"
            print("❌ Get avatars failed (\(resp)): \(bodyText)")
            throw URLError(.badServerResponse)
        }
        
        let avatars = try JSONDecoder().decode([Avatar].self, from: data)
        return avatars
    }
    
    // Update avatar
    static func updateAvatar(_ avatarId: String, request: UpdateAvatarRequest, authToken: String, providerId: String) async throws -> Avatar {
        var req = URLRequest(url: baseURL.appendingPathComponent("api/avatars/\(avatarId)"))
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        setHMACHeaders(&req, authToken: authToken, providerId: providerId)
        
        req.httpBody = try JSONEncoder().encode(request)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "No body"
            print("❌ Avatar update failed (\(resp)): \(bodyText)")
            throw URLError(.badServerResponse)
        }
        
        let avatar = try JSONDecoder().decode(Avatar.self, from: data)
        return avatar
    }
    
    // Set active avatar
    static func setActiveAvatar(_ avatarId: String, authToken: String, providerId: String) async throws -> Avatar {
        var req = URLRequest(url: baseURL.appendingPathComponent("api/avatars/\(avatarId)/activate"))
        req.httpMethod = "POST"
        setHMACHeaders(&req, authToken: authToken, providerId: providerId)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "No body"
            print("❌ Set active avatar failed (\(resp)): \(bodyText)")
            throw URLError(.badServerResponse)
        }
        
        let avatar = try JSONDecoder().decode(Avatar.self, from: data)
        return avatar
    }
}
