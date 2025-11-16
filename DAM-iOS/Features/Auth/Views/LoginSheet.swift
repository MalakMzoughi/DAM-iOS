//
//  LoginSheet.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI

struct LoginSheet: View {
    @EnvironmentObject var session: UserSession   // still available if you need it later
    @EnvironmentObject var router: AppRouter      // same here
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Login")
                .font(.title.bold())

            // GOOGLE BUTTON
            Button {
                authViewModel.signInWithGoogleTapped()
            } label: {
                HStack(spacing: 12) {
                    if let _ = UIImage(named: "google") {
                        AppImages.google
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    } else {
                        // Fallback icon
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20))
                    }

                    Text("Continue with Google")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
                .cornerRadius(8)
            }
            .disabled(authViewModel.isLoading)
            .opacity(authViewModel.isLoading ? 0.7 : 1.0)

            // Loading indicator
            if authViewModel.isLoading {
                ProgressView()
                    .padding(.top, 4)
            }

            // Error message
            if let errorText = authViewModel.errorMessage {
                Text(errorText)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: 420)
    }
}

