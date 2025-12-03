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
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            return try jsonDecoder.decode([Sublevel].self, from: data)
        } catch {
            print("❌ SublevelRepository.getSublevelsByLevel error:", error)
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
