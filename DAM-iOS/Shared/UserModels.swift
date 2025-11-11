//
//  UserModels.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 10/11/2025.
//

import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String
    let name: String
    let email: String?
    let photoUrl: URL?
    let provider: String?      // "google" | "facebook" | "apple" | nil (guest)
    let level: Int
    let totalStars: Int
    let maxStars: Int
}

extension UserProfile {
    static let guest = UserProfile(
        id: "guest",
        name: "Guest Player",
        email: nil,
        photoUrl: nil,
        provider: nil,
        level: 1,
        totalStars: 0,
        maxStars: 24
    )
}

enum AuthState {
    case guest(UserProfile)
    case loggedIn(UserProfile)
}
