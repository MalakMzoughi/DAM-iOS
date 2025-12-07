//
//  SublevelRepository.swift
//  DAM-iOS
//
//  Simple repository to fetch sublevels from backend
//

import Foundation

final class SublevelRepository {

    private var jsonDecoder: JSONDecoder {
        let d = JSONDecoder()
        return d
    }

    // Fetch sublevels for a given level ID
    func getSublevelsByLevel(_ levelId: String) async -> [Sublevel]? {
        let urlString = "\(API.base)/sublevels/level/\(levelId)"
        print("🔷 SublevelRepo: Fetching from URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("❌ SublevelRepo: Invalid URL")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse {
                print("🔷 SublevelRepo: Status \(http.statusCode)")
            }
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("❌ SublevelRepo: Bad status code")
                return nil
            }
            let decoded = try jsonDecoder.decode([Sublevel].self, from: data)
            print("✅ SublevelRepo: Decoded \(decoded.count) sublevels")
            return decoded
        } catch {
            print("❌ SublevelRepo error:", error)
            return nil
        }
    }

    // Fetch single sublevel by id
    func getSublevelById(_ id: String) async -> Sublevel? {
        let urlString = "\(API.base)/sublevels/\(id)"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            return try jsonDecoder.decode(Sublevel.self, from: data)
        } catch {
            print("❌ SublevelRepository.getSublevelById error:", error)
            return nil
        }
    }
}
