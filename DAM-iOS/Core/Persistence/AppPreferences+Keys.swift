import Foundation

extension AppPreferences.Key {
    /// Flag indicating the user finished the level-intro walkthrough.
    static let didSeeLevelIntro = AppPreferences.Key("didSeeLevelIntro")

    /// Persistent star total cached locally for quick display.
    static let cachedStarCount = AppPreferences.Key("cachedStarCount")

    /// Snapshot of the level list returned by the backend.
    static let cachedLevels = AppPreferences.Key("cachedLevels")

    /// Cached unlocked-level response keyed by ID for quick boot.
    static let cachedProgressByLevel = AppPreferences.Key("cachedProgressByLevel")
}
