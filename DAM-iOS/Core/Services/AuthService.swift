//
//  AuthService.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import Foundation

// MARK: - DTOs coming from / going to the backend

struct SocialLoginBody: Codable {
    let token: String
    let provider: String   // "google" or "facebook"
}

struct AuthResponseDto: Codable {
    let providerId: String
    let authToken: String
    let user: BackendUser
}

struct BackendUser: Codable {
    let id: String
    let email: String?
    let name: String
    let photoUrl: String?
    let provider: String
    let providerId: String
    let score: Int
    let level: Int
}

// MARK: - Mapping backend user → your app profile

extension BackendUser {
    var asUserProfile: UserProfile {
        UserProfile(
            id: id,
            name: name,
            email: email,
            photoUrl: URL(string: photoUrl ?? ""),
            provider: provider,
            providerId: providerId,
            level: level,
            totalStars: max(0, score / 100),
            maxStars: 24
        )
    }
}

enum API {
    static let base = URL(string: "http://127.0.0.1:3000/")!
}

// MARK: - AuthService

@MainActor
final class AuthService {

    private let googleProvider: GoogleAuthProviding

    // No default parameter here (avoids actor issues)
    init(googleProvider: GoogleAuthProviding) {
        self.googleProvider = googleProvider
    }

    // MARK: - Google login flow

    func signInWithGoogle() async throws -> (authToken: String, profile: UserProfile) {
        // 1) Get Google idToken
        let idToken = try await googleProvider.signInAndGetIDToken()

        // 2) Call your backend
        var request = URLRequest(url: API.base.appendingPathComponent("auth/social-login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = SocialLoginBody(token: idToken, provider: "google")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let dto = try JSONDecoder().decode(AuthResponseDto.self, from: data)
        let profile = dto.user.asUserProfile

        print("✅ Auth success for user:", profile.name, "| providerId:", dto.providerId)

        return (dto.authToken, profile)
    }

    func signOut() {
        googleProvider.signOut()
    }
}

