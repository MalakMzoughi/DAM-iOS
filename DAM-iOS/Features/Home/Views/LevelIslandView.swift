//
//  LevelIslandView.swift
//  DAM-iOS
//
//  Created by Malak on 14/11/2025.
//
import SwiftUI

struct LevelIslandView: View {
    let level: Level

    var body: some View {
        ZStack {
            // Island
            Image(level.islandAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 160)

            // Level button + stars
            VStack(spacing: 4) {
                // Level number circle (acts like a button visually)
                Text("\(level.index)")
                    .font(.headline)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.9))
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                level.state == .locked
                                ? Color.gray
                                : Color.orange,
                                lineWidth: 2
                            )
                    )
                    .shadow(radius: 3)

                // Stars (over the island, under the level circle visually)
                HStack(spacing: 2) {
                    ForEach(0..<level.maxStars, id: \.self) { i in
                        Image(systemName: i < level.earnedStars ? "star.fill" : "star.fill")
                            .font(.caption)
                            .foregroundStyle(
                                i < level.earnedStars
                                ? Color.yellow
                                : Color.gray.opacity(0.4)
                            )
                    }
                }
            }
            .offset(y: -20) // bring UI slightly towards top of the island

            // Lock icon (if level is locked)
            if level.state == .locked {
                Image(systemName: "lock.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Circle().fill(Color.black.opacity(0.6)))
                    .offset(x: 70, y: -50)
            }
        }
    }
}
