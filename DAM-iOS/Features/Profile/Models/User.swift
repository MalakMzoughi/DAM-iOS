//
//  User.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String
    let name: String
    let email: String?
    let photoUrl: URL?
    let provider: String
    let providerId: String
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
        provider: "",
        providerId: "",
        level: 1,
        totalStars: 0,
        maxStars: 24
    )
    
    func updating(name: String? = nil,
                  level: Int? = nil,
                  totalStars: Int? = nil) -> UserProfile {
        UserProfile(
            id: id,
            name: name ?? self.name,
            email: email,
            photoUrl: photoUrl,
            provider: provider,
            providerId: providerId,
            level: level ?? self.level,
            totalStars: totalStars ?? self.totalStars,
            maxStars: maxStars
        )
    }
}
