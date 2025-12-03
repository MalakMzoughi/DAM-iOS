//
//  AppPreferences.swift
//  DAM-iOS
//
//  Lightweight key-value store mirroring Android's SharedPreferences
//

import Foundation

/// Centralized helper for reading and writing small bits of state.
/// Wraps `UserDefaults` but exposes an API similar to Android's SharedPreferences.
final class AppPreferences {
    static let shared = AppPreferences()

    /// Allows callers to plug in custom stores (useful for testing).
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Key Definition

    /// Namespace for strongly-typed keys.
    /// Extend this enum with additional cases as needed.
    struct Key: RawRepresentable, Hashable {
        let rawValue: String

        init(rawValue: String) {
            self.rawValue = rawValue
        }

        init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        // Example keys – feel free to add your own in extensions.
        static let hasCompletedOnboarding = Key("hasCompletedOnboarding")
        static let preferredPianoMode = Key("preferredPianoMode")
        static let lastVisitedLevelId = Key("lastVisitedLevelId")
    }

    // MARK: - Primitive Values

    func set(_ value: Bool, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    func set(_ value: Int, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    func set(_ value: Double, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    func set(_ value: String, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    func set(_ value: Data, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    func bool(for key: Key, default defaultValue: Bool = false) -> Bool {
        if defaults.object(forKey: key.rawValue) == nil {
            return defaultValue
        }
        return defaults.bool(forKey: key.rawValue)
    }

    func int(for key: Key, default defaultValue: Int = 0) -> Int {
        if defaults.object(forKey: key.rawValue) == nil {
            return defaultValue
        }
        return defaults.integer(forKey: key.rawValue)
    }

    func double(for key: Key, default defaultValue: Double = 0.0) -> Double {
        if defaults.object(forKey: key.rawValue) == nil {
            return defaultValue
        }
        return defaults.double(forKey: key.rawValue)
    }

    func string(for key: Key, default defaultValue: String? = nil) -> String? {
        return defaults.string(forKey: key.rawValue) ?? defaultValue
    }

    func data(for key: Key) -> Data? {
        defaults.data(forKey: key.rawValue)
    }

    // MARK: - Codable Support

    func setCodable<T: Codable>(_ value: T, for key: Key) {
        do {
            let data = try JSONEncoder().encode(value)
            defaults.set(data, forKey: key.rawValue)
        } catch {
            print("⚠️ AppPreferences: failed to encode \(T.self) for key \(key.rawValue): \(error)")
        }
    }

    func codable<T: Codable>(_ type: T.Type, for key: Key) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("⚠️ AppPreferences: failed to decode \(T.self) for key \(key.rawValue): \(error)")
            return nil
        }
    }

    // MARK: - Removal

    func remove(_ key: Key) {
        defaults.removeObject(forKey: key.rawValue)
    }

    func removeAll(_ keys: [Key]) {
        keys.forEach { defaults.removeObject(forKey: $0.rawValue) }
    }
}
