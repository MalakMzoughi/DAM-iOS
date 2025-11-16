//
//  AuthViewModel.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import Foundation

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    @Published var userProfile: UserProfile?
    @Published var lastAuthToken: String?

    private let authService: AuthService

    // MARK: - Initializer
    init(authService: AuthService) {
        self.authService = authService
    }

    // Factory for SwiftUI
    static func make() -> AuthViewModel {
        // We are on @MainActor here, so it's legal to call @MainActor inits
        let googleProvider = GoogleAuthProvider()
        let authService = AuthService(googleProvider: googleProvider)
        return AuthViewModel(authService: authService)
    }

    // MARK: - User taps "Login with Google"
    func signInWithGoogleTapped() {
        Task {
            await signInWithGoogle()
        }
    }

    // MARK: - Main Sign-In Logic
    private func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            let (authToken, profile) = try await authService.signInWithGoogle()

            lastAuthToken = authToken
            userProfile = profile
            print("🔐 Received authToken:", authToken)

            isAuthenticated = true

        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }

        isLoading = false
    }

    // MARK: - Sign Out
    func signOutTapped() {
        authService.signOut()

        userProfile = nil
        lastAuthToken = nil
        isAuthenticated = false
        errorMessage = nil
        isLoading = false
    }
}
