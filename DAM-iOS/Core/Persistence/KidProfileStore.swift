import Foundation

/// Stores kid onboarding profiles locally so players can create and reuse magic names
/// even before we plug them into the real backend accounts system.
final class KidProfileStore {
    static let shared = KidProfileStore()

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Public API

    func activeProfile() -> KidProfile? {
        guard let normalized = defaults.string(forKey: Keys.activeUniqueName) else { return nil }
        return profile(normalized: normalized)
    }

    func save(_ profile: KidProfile, setActive: Bool = true) {
        let normalized = normalize(profile.uniqueName)
        guard let data = try? encoder.encode(profile) else { return }
        defaults.set(data, forKey: key(for: normalized))

        var names = registeredNames()
        names.insert(normalized)
        persistRegistered(names)

        if setActive {
            defaults.set(normalized, forKey: Keys.activeUniqueName)
        }
    }

    func release(_ uniqueName: String) {
        let normalized = normalize(uniqueName)
        var names = registeredNames()
        names.remove(normalized)
        persistRegistered(names)
    }

    func profile(named uniqueName: String) -> KidProfile? {
        profile(normalized: normalize(uniqueName))
    }

    func allProfiles() -> [KidProfile] {
        registeredNames().compactMap { profile(normalized: $0) }
    }

    func deleteProfile(named uniqueName: String) {
        let normalized = normalize(uniqueName)
        defaults.removeObject(forKey: key(for: normalized))

        var names = registeredNames()
        names.remove(normalized)
        persistRegistered(names)

        if defaults.string(forKey: Keys.activeUniqueName) == normalized {
            defaults.removeObject(forKey: Keys.activeUniqueName)
        }
    }

    func clearActiveProfile() {
        defaults.removeObject(forKey: Keys.activeUniqueName)
    }

    func isNameTaken(_ uniqueName: String, ignoring profile: KidProfile? = nil) -> Bool {
        let normalized = normalize(uniqueName)
        if let current = profile, normalize(current.uniqueName) == normalized {
            return false
        }
        return registeredNames().contains(normalized)
    }

    func validateUniqueName(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Pick a magic name." }
        if trimmed.count < 3 { return "Use at least 3 characters." }
        if trimmed.count > 18 { return "Keep it under 18 characters." }
        let regex = "^[A-Za-z0-9_]+$"
        if trimmed.range(of: regex, options: .regularExpression) == nil {
            return "Letters, numbers, or _ only."
        }
        return nil
    }

    func buildAlias(for uniqueName: String) -> String {
        "\(normalize(uniqueName))@pianokids.fun"
    }

    // MARK: - Private helpers

    private func profile(normalized: String) -> KidProfile? {
        guard let data = defaults.data(forKey: key(for: normalized)) else { return nil }
        return try? decoder.decode(KidProfile.self, from: data)
    }

    private func registeredNames() -> Set<String> {
        let stored = defaults.array(forKey: Keys.registeredNames) as? [String] ?? []
        return Set(stored)
    }

    private func persistRegistered(_ names: Set<String>) {
        defaults.set(Array(names), forKey: Keys.registeredNames)
    }

    private func key(for normalized: String) -> String {
        Keys.profilePrefix + normalized
    }

    private func normalize(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private enum Keys {
        static let registeredNames = "kidProfiles.registered"
        static let activeUniqueName = "kidProfiles.active"
        static let profilePrefix = "kidProfiles.profile."
    }
}
