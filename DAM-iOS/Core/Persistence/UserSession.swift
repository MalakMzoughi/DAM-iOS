//
//  UserSession.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI

/// Represents the authentication state of the app
enum AuthState {
    case guest(UserProfile)
    case loggedIn(UserProfile)
}

@MainActor
final class UserSession: ObservableObject {

    // MARK: - Published session state
    @Published private(set) var state: AuthState = .guest(.guest)

    // Store JWT from backend (renamed to authToken)
    @Published private(set) var authToken: String? = nil
    
    // Store provider ID for HMAC auth
    var providerId: String? {
        return profile.providerId
    }
    
    // Active avatar
    @Published var activeAvatar: Avatar? = nil

    // MARK: - Access current user profile
    var profile: UserProfile {
        switch state {
        case .guest(let p):
            return p
        case .loggedIn(let p):
            return p
        }
    }

    // MARK: - Session Mutations

    func setLoggedIn(authToken: String, profile: UserProfile) {
        self.authToken = authToken
        self.state = .loggedIn(profile)

        print("🎉 Logged in as:", profile.name)
        print("🔐 Stored authToken:", authToken)
    }

    func setGuest() {
        self.authToken = nil
        self.state = .guest(.guest)

        print("👤 User is now a guest")
    }
    
    func setActiveAvatar(_ avatar: Avatar?) {
        self.activeAvatar = avatar
        if let avatar = avatar {
            print("✅ Active avatar set: \(avatar.name)")
        } else {
            print("✅ Active avatar cleared (using default)")
        }
    }
}

