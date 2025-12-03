//
//  UserDefaultsService.swift
//  DAM-iOS
//
//  Service for managing UserDefaults storage
//

import Foundation

/// Legacy helper used by avatar flows. Prefer `AppPreferences` for new data.
class UserDefaultsService {
    static let shared = UserDefaultsService()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Avatar Storage Keys
    private enum Keys {
        static let avatarURL = "avatarURL"
        static let avatarThumbnail = "avatarThumbnail"
        static let avatarGLB = "avatarGLB"
        static let avatarId = "avatarId"
        static let avatarSetupComplete = "avatarSetupComplete"
        static let userId = "userId"
    }
    
    // MARK: - Avatar Methods
    func saveAvatarURL(_ url: String) {
        defaults.set(url, forKey: Keys.avatarURL)
    }
    
    func getAvatarURL() -> String? {
        return defaults.string(forKey: Keys.avatarURL)
    }
    
    func saveAvatarThumbnail(_ url: String) {
        defaults.set(url, forKey: Keys.avatarThumbnail)
    }
    
    func getAvatarThumbnail() -> String? {
        return defaults.string(forKey: Keys.avatarThumbnail)
    }
    
    func saveAvatarGLB(_ url: String) {
        defaults.set(url, forKey: Keys.avatarGLB)
    }
    
    func getAvatarGLB() -> String? {
        return defaults.string(forKey: Keys.avatarGLB)
    }
    
    func completeAvatarSetup(avatarId: String) {
        defaults.set(avatarId, forKey: Keys.avatarId)
        defaults.set(true, forKey: Keys.avatarSetupComplete)
    }
    
    func isAvatarSetupComplete() -> Bool {
        return defaults.bool(forKey: Keys.avatarSetupComplete)
    }
    
    func getAvatarId() -> String? {
        return defaults.string(forKey: Keys.avatarId)
    }
    
    // MARK: - User ID
    func saveUserId(_ userId: String) {
        defaults.set(userId, forKey: Keys.userId)
    }
    
    func getUserId() -> String? {
        return defaults.string(forKey: Keys.userId)
    }
}

