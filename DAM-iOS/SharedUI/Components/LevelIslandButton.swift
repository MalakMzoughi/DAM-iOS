//
//  LevelIslandButton.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 23/11/2025.
//

import SwiftUI

struct LevelIslandButton: View {
    let level: Level
    let unlockedItem: UnlockedLevelItem?
    let onTap: () -> Void

    var isUnlocked: Bool {
        unlockedItem?.unlocked ?? false
    }

    var stars: Int {
        unlockedItem?.starsUnlocked ?? 0
    }

    var body: some View {
        VStack(spacing: 8) {

            // Level card
            Button(action: onTap) {
                VStack(spacing: 6) {
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    } else {
                        Text("🎵").font(.title2)
                    }

                    Text(level.title)
                        .font(.caption)
                        .bold()
                        .multilineTextAlignment(.center)

                    if isUnlocked {
                        HStack(spacing: 4) {
                            ForEach(0..<3) { i in
                                Image(systemName: "star.fill")
                                    .foregroundColor(i < stars ? .yellow : .gray.opacity(0.4))
                                    .font(.caption)
                            }
                        }
                    } else {
                        Text("Locked")
                            .foregroundColor(.gray)
                            .font(.caption2)
                    }
                }
                .padding(10)
                .frame(width: 110, height: 110)
                .background(isUnlocked ? Color.white : Color.gray.opacity(0.2))
                .cornerRadius(16)
                .shadow(radius: 4)
            }

            // Island image
            if let url = URL(string: level.islandImageUrl) {
                AsyncImage(url: url) { img in
                    img.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 180, height: 140)
            }
        }
    }
}
