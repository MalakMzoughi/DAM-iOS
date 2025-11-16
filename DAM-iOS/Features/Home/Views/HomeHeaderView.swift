//
//  HomeHeaderView.swift
//  DAM-iOS
//
//  Created by Malak on 14/11/2025.
//

import SwiftUI

struct HomeHeaderView: View {
    let profile: UserProfile
    let isLoggedIn: Bool
    let totalStars: Int
    let onBackTap: () -> Void
    let onProfileTap: () -> Void  // This will now navigate to profile
    let onAddAvatarTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: onBackTap) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(8)
                    .background(Color.white.opacity(0.95))
                    .clipShape(Capsule())
                    .shadow(radius: 2)
            }

            Spacer(minLength: 8)

            // Avatar / piano + name - NOW GOES TO PROFILE
            Button(action: onProfileTap) {
                HStack(spacing: 8) {
                    if isLoggedIn {
                        RemoteAvatar(url: profile.photoUrl, size: 40)
                    } else {
                        RemoteAvatar(url: nil, size: 40)
                    }

                    Text(profile.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.95))
                .clipShape(Capsule())
                .shadow(radius: 2)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            // Add Avatar Button (only for logged in users)
            if isLoggedIn {
                Button(action: onAddAvatarTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("Add Avatar")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.95))
                    .clipShape(Capsule())
                    .shadow(radius: 2)
                }
            }

            Spacer(minLength: 8)

            // Stars badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(totalStars)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.white.opacity(0.95))
            .clipShape(Capsule())
            .shadow(radius: 2)
        }
    }
}
