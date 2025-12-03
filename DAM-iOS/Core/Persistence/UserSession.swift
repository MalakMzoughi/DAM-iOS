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
        return profile.providerId.isEmpty ? nil : profile.providerId
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
    
    // MARK: - Convenience flags
    var isLoggedIn: Bool {
        if case .loggedIn = state { return true }
        return false
    }


    // MARK: - Session Mutations

    func setLoggedIn(authToken: String, profile: UserProfile) {
        self.authToken = authToken
        self.state = .loggedIn(profile)
        
        // Save credentials to UserDefaults for API calls
        UserDefaults.standard.set(authToken, forKey: "authToken")
        if !profile.providerId.isEmpty {
            UserDefaults.standard.set(profile.providerId, forKey: "providerId")
        }

        print("🎉 Logged in as:", profile.name)
        print("🔐 Stored authToken:", authToken)
        print("💾 Saved auth credentials to UserDefaults")
    }

    func setGuest() {
        self.authToken = nil
        self.state = .guest(.guest)
        
        // Clear credentials from UserDefaults
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "providerId")

        print("👤 User is now a guest")
        print("🗑️ Cleared auth credentials from UserDefaults")
    }
    
    func setActiveAvatar(_ avatar: Avatar?) {
        self.activeAvatar = avatar
        if let avatar = avatar {
            print("✅ Active avatar set: \(avatar.name)")
        } else {
            print("✅ Active avatar cleared (using default)")
        }
    }

    func updateProfileName(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let updatedProfile = profile.updating(name: trimmed)

        switch state {
        case .guest:
            state = .guest(updatedProfile)
        case .loggedIn:
            state = .loggedIn(updatedProfile)
        }
    }
    
    // MARK: - Progress update (used by HomeScreenViewModel)
    func updateStarsAndLevel(stars: Int, level: Int?) {
        let updatedProfile = profile.updating(
            level: level ?? profile.level,
            totalStars: stars
        )

        switch state {
        case .guest:
            state = .guest(updatedProfile)
        case .loggedIn:
            state = .loggedIn(updatedProfile)
        }
    }

}
