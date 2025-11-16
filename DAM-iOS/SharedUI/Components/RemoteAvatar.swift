//
//  RemoteAvatar.swift
//  DAM-iOS
//
//  Created by Malak on 14/11/2025.
//

import SwiftUI

struct RemoteAvatar: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if url != nil {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .empty:
                        ProgressView()

                    case .failure:
                        fallback

                    @unknown default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
        )
        .contentShape(Circle())
    }

    // MARK: - Fallback (guest / no image / loading failed)
    private var fallback: some View {
        ZStack {
            Circle()
                .fill(AppColors.rainbowPink.opacity(0.25))

            Image(systemName: "pianokeys.inverse")   // or your piano asset
                .font(.system(size: size * 0.52, weight: .bold))
                .foregroundStyle(AppColors.rainbowBlue)
        }
    }
}
