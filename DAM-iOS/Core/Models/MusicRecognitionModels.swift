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
    let confidence: Int
    
    // Custom decoder to handle both Int and Double
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        album = try container.decode(String.self, forKey: .album)
        
        // Try to decode as Int first, then Double
        if let intValue = try? container.decode(Int.self, forKey: .confidence) {
            confidence = intValue
        } else if let doubleValue = try? container.decode(Double.self, forKey: .confidence) {
            confidence = Int(doubleValue)
        } else {
            confidence = 0
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case title, artist, album, confidence
    }
}
