//
//  MusicRecognitionModels.swift
//  DAM-iOS
//
//  Music recognition models
//

import Foundation

// MARK: - Music Recognition Response
struct MusicRecognitionResponse: Codable {
    let title: String
    let artist: String
    let album: String
    let confidence: Double
}
