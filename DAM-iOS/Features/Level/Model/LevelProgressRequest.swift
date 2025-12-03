//
//  LevelProgressRequest.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 23/11/2025.
//

import Foundation

struct LevelProgressRequest: Codable {
    let userId: String
    let levelId: String
    let stars: Int
    let score: Int
    let completed: Bool
}
