//
//  GoogleAuthProvider.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI
import GoogleSignIn

enum GoogleSignInError: Error {
    case failed
    case noIDToken
}

/// Protocol so later you can plug in a fake provider for tests if needed
@MainActor
protocol GoogleAuthProviding {
    func signInAndGetIDToken() async throws -> String
    func signOut()
}

@MainActor
final class GoogleAuthProvider: GoogleAuthProviding {

    // MARK: - Public API

    /// Returns the Google **idToken** to send to your NestJS backend.
    func signInAndGetIDToken() async throws -> String {
        guard let presenting = presentingViewController() else {
            throw GoogleSignInError.failed
        }

        // 1) Try restoring previous session
        if let restored = try? await GIDSignIn.sharedInstance.restorePreviousSignIn(),
           let idToken = restored.idToken?.tokenString {
            return idToken
        }

        // 2) Start a new Google Sign-In flow
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let token = result?.user.idToken?.tokenString else {
                    continuation.resume(throwing: GoogleSignInError.noIDToken)
                    return
                }

                continuation.resume(returning: token)
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    // MARK: - Private helpers

    private func presentingViewController() -> UIViewController? {
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}


