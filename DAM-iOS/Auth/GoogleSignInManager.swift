//
//  GoogleSignInManager.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 10/11/2025.
//

import SwiftUI
import GoogleSignIn

enum GoogleSignInError: Error { case failed, noIDToken }

@MainActor
final class GoogleSignInManager {
    static let shared = GoogleSignInManager()

    private func presentingViewController() -> UIViewController? {
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    /// Returns the Google **idToken** to send to /auth/social-login
    func signInAndGetIDToken() async throws -> String {
        guard let presenting = presentingViewController() else { throw GoogleSignInError.failed }

        // Try restoring a previous session first
        if let restored = try? await GIDSignIn.sharedInstance.restorePreviousSignIn(),
           let idToken  = restored.idToken?.tokenString {
            return idToken
        }

        // Start a new flow
        return try await withCheckedThrowingContinuation { cont in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { result, error in
                if let error = error { cont.resume(throwing: error); return }
                guard let token = result?.user.idToken?.tokenString else {
                    cont.resume(throwing: GoogleSignInError.noIDToken)
                    return
                }
                cont.resume(returning: token)
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
}
