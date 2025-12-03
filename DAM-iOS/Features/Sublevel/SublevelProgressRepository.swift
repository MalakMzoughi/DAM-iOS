import Foundation

/// Handles calls to /sublevels/progress for fetching unlock data and saving progress.
final class SublevelProgressRepository {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let baseURL = API.base

    func getUserSublevels(userId: String, levelId: String) async -> [Sublevel]? {
        let urlString = "\(baseURL)/sublevels/progress/\(userId)/\(levelId)"
        guard let url = URL(string: urlString) else {
            print("❌ SublevelProgressRepository.getUserSublevels – invalid URL")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                if let http = response as? HTTPURLResponse {
                    print("❌ SublevelProgressRepository.getUserSublevels – status: \(http.statusCode)")
                }
                return nil
            }
            return try decoder.decode([Sublevel].self, from: data)
        } catch {
            print("❌ SublevelProgressRepository.getUserSublevels error:", error)
            return nil
        }
    }

    func saveProgress(_ request: SublevelProgressRequest) async -> [Sublevel]? {
        let urlString = "\(baseURL)/sublevels/progress"
        guard let url = URL(string: urlString) else {
            print("❌ SublevelProgressRepository.saveProgress – invalid URL")
            return nil
        }

        do {
            var httpRequest = URLRequest(url: url)
            httpRequest.httpMethod = "POST"
            httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            httpRequest.httpBody = try encoder.encode(request)

            let (data, response) = try await URLSession.shared.data(for: httpRequest)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                if let http = response as? HTTPURLResponse {
                    print("❌ SublevelProgressRepository.saveProgress – status: \(http.statusCode)")
                }
                return nil
            }

            return try decoder.decode([Sublevel].self, from: data)
        } catch {
            print("❌ SublevelProgressRepository.saveProgress error:", error)
            return nil
        }
    }
}
