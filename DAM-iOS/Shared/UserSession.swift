//
//  UserSession.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 10/11/2025.
//

// UserSession.swift
import SwiftUI

@MainActor
final class UserSession: ObservableObject {
    @Published private(set) var state: AuthState = .guest(.guest)
    @Published private(set) var jwt: String? = nil

    // Access current profile (guest or logged-in)
    var profile: UserProfile {
        switch state {
        case .guest(let p): return p
        case .loggedIn(let p): return p
        }
    }

    func setLoggedIn(jwt: String, profile: UserProfile) {
        self.jwt = jwt
        self.state = .loggedIn(profile)
        print("!!!!!!! LOGGED IN AS: ", profile.name)
    }

    func setGuest() {
        self.jwt = nil
        self.state = .guest(.guest)
    }
}

extension UserSession {
    func loginWithGoogle() async throws {
        let idToken = try await GoogleSignInManager.shared.signInAndGetIDToken()
        let result = try await AuthAPI.socialLoginGoogle(idToken: idToken)
        self.setLoggedIn(jwt: result.jwt, profile: result.profile)
    }

    func logoutFromGoogle() {
        GoogleSignInManager.shared.signOut()
        setGuest()
    }
}
