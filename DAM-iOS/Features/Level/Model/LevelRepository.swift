//
//  LevelRepository.swift
//  DAM-iOS
//
//  Enhanced with detailed debugging
//

import Foundation

final class LevelRepository {

    // MARK: - Base URL
    private let baseURL = API.base

    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        return decoder
    }

    private var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        return encoder
    }

    // MARK: - Fetch all levels (/levels)
    func getAllLevels() async -> [Level]? {
        let urlString = "\(baseURL)/levels"
        print("🌐 getAllLevels - URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ getAllLevels - Invalid URL: \(urlString)")
            return nil
        }

        do {
            print("📡 getAllLevels - Making request...")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Debug response
            if let http = response as? HTTPURLResponse {
                print("📊 getAllLevels - Status Code: \(http.statusCode)")
                print("📊 getAllLevels - Headers: \(http.allHeaderFields)")
            }
            
            // Debug raw data
            print("📦 getAllLevels - Data size: \(data.count) bytes")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 getAllLevels - Raw JSON: \(jsonString.prefix(500))...") // First 500 chars
            }
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                if let http = response as? HTTPURLResponse {
                    print("❌ getAllLevels - Bad status code: \(http.statusCode)")
                }
                return nil
            }
            
            let levels = try jsonDecoder.decode([Level].self, from: data)
            print("✅ getAllLevels - Successfully decoded \(levels.count) levels")
            
            // Debug first level
            if let first = levels.first {
                print("🔍 First level: id=\(first.id), order=\(first.order), title=\(first.title)")
                print("🔍 MapPosition: x=\(first.mapPosition.x), y=\(first.mapPosition.y)")
            }
            
            return levels
        } catch let decodingError as DecodingError {
            print("❌ getAllLevels - Decoding error:")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            case .typeMismatch(let type, let context):
                print("   Type mismatch for type '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("   Debug: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   Value not found for type '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            case .dataCorrupted(let context):
                print("   Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("   Debug: \(context.debugDescription)")
            @unknown default:
                print("   Unknown decoding error: \(decodingError)")
            }
            return nil
        } catch {
            print("❌ getAllLevels - Network/Other error: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Fetch level by ID (/levels/:id)
    func getLevelById(_ levelId: String) async -> Level? {
        let urlString = "\(baseURL)/levels/\(levelId)"
        print("🌐 getLevelById - URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ getLevelById - Invalid URL")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let http = response as? HTTPURLResponse {
                print("📊 getLevelById - Status: \(http.statusCode)")
            }
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            return try jsonDecoder.decode(Level.self, from: data)
        } catch {
            print("❌ getLevelById error:", error)
            return nil
        }
    }


    // MARK: - Fetch unlocked levels (/levels/unlocked/:userId)
    func getUnlockedLevels(userId: String) async -> UnlockedLevelsResponse? {
        let urlString = "\(baseURL)/levels/unlocked/\(userId)"
        print("🌐 getUnlockedLevels - URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ getUnlockedLevels - Invalid URL")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let http = response as? HTTPURLResponse {
                print("📊 getUnlockedLevels - Status: \(http.statusCode)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 getUnlockedLevels - Raw JSON: \(jsonString.prefix(500))...")
            }
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            
            let result = try jsonDecoder.decode(UnlockedLevelsResponse.self, from: data)
            print("✅ getUnlockedLevels - Decoded \(result.levels.count) unlocked levels")
            
            return result
        } catch {
            print("❌ getUnlockedLevels error:", error)
            return nil
        }
    }
}
