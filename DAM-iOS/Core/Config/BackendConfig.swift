import Foundation

/// Central place to configure the backend base URL so every service stays in sync.
/// Reads the value from Info.plist ("API_BASE_URL") and falls back to the default LAN URL
/// used by the Android client so both apps hit the same server during development.
enum BackendConfig {
    private static let fallbackBaseURL = "http://192.168.100.52:3000"

    static let baseURL: URL = {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           let url = URL(string: configured), !configured.isEmpty {
            return url
        }

        guard let url = URL(string: fallbackBaseURL) else {
            fatalError("Invalid fallback backend URL: \(fallbackBaseURL)")
        }
        return url
    }()
}
