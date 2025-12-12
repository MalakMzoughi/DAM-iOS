import Foundation

extension URL {
    /// Resolves a backend asset path (either absolute URL or relative path on the API host)
    static func backendAsset(from path: String?) -> URL? {
        guard let raw = path?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }

        if let absolute = URL(string: raw), absolute.scheme != nil {
            return absolute
        }

        let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return BackendConfig.baseURL.appendingPathComponent(trimmed)
    }
}
