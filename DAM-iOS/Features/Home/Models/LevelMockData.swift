//
//  LevelMockData.swift
//  DAM-iOS
//
//  Created by Malak on 14/11/2025.
//

import CoreGraphics

struct LevelMockData {
    static let levels: [Level] = [
        Level(
            id: 1,
            index: 1,
            name: "Mischief Manor",
            islandAsset: "level_1",
            badgeIcon: "icon_mouse",
            maxStars: 3,
            earnedStars: 3,
            state: .completed,
            position: CGPoint(x: 0.15, y: 0.70)
        ),
        Level(
            id: 2,
            index: 2,
            name: "Web of Justice",
            islandAsset: "level_2",
            badgeIcon: "icon_spider",
            maxStars: 3,
            earnedStars: 2,
            state: .completed,
            position: CGPoint(x: 0.35, y: 0.55)
        ),
        Level(
            id: 3,
            index: 3,
            name: "Moonlight Magic",
            islandAsset: "level_3",
            badgeIcon: "icon_moon",
            maxStars: 3,
            earnedStars: 1,
            state: .unlocked,
            position: CGPoint(x: 0.55, y: 0.40)
        ),
        Level(
            id: 4,
            index: 4,
            name: "Electric Meadow",
            islandAsset: "level_4",
            badgeIcon: "icon_lightning",
            maxStars: 3,
            earnedStars: 0,
            state: .locked,
            position: CGPoint(x: 0.75, y: 0.55)
        ),
        Level(
            id: 5,
            index: 5,
            name: "Shield of Justice",
            islandAsset: "level_5",
            badgeIcon: "icon_shield",
            maxStars: 3,
            earnedStars: 0,
            state: .locked,
            position: CGPoint(x: 0.60, y: 0.80)
        ),
        Level(
            id: 6,
            index: 6,
            name: "Hidden Village",
            islandAsset: "level_6",
            badgeIcon: "icon_village",
            maxStars: 3,
            earnedStars: 0,
            state: .locked,
            position: CGPoint(x: 0.85, y: 0.75)
        )
    ]
}
