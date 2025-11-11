//
//  AuthAPI.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 10/11/2025.
//

import Foundation

struct SocialLoginBody: Codable {
    let token: String
    let provider: String   // "google"
}

struct AuthResponseDto: Codable {
    let accessToken: String
    let user: BackendUser
}

struct BackendUser: Codable {
    let id: String
    let email: String?
    let name: String
    let photoUrl: String?
    let provider: String
    let score: Int
    let level: Int
}

// Map backend user → your app profile
extension BackendUser {
    var asUserProfile: UserProfile {
        UserProfile(
            id: id,
            name: name,
            email: email,
            photoUrl: URL(string: photoUrl ?? ""),
            provider: provider,
            level: level,
            totalStars: max(0, score / 100),   // matches Android teammate
            maxStars: 24
        )
    }
}

enum API {
    static let base = URL(string: "http://127.0.0.1:3000/")!  
}

enum AuthAPI {
    static func socialLoginGoogle(idToken: String) async throws -> (jwt: String, profile: UserProfile) {
        var req = URLRequest(url: API.base.appendingPathComponent("auth/social-login"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = SocialLoginBody(token: idToken, provider: "google")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let dto = try JSONDecoder().decode(AuthResponseDto.self, from: data)
        print("!!!!!! DECODED USER:", dto.user.name)
        return (dto.accessToken, dto.user.asUserProfile)
    }
}
