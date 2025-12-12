//
//  HomeScreenViewModel.swift
//  DAM-iOS
//

import SwiftUI

@MainActor
class HomeScreenViewModel: ObservableObject {

    // ----------------------------------------------------
    // PUBLISHED STATE
    // ----------------------------------------------------
    @Published var levels: [Level] = []
    @Published var progressById: [String: UnlockedLevelItem] = [:]
    @Published var isLoading: Bool = false

    private let repo = LevelRepository()

    // ----------------------------------------------------
    // COMPUTED
    // ----------------------------------------------------
    var totalStars: Int {
        progressById.values.reduce(0) { $0 + $1.starsUnlocked }
    }

    var unlockedCount: Int {
        progressById.values.filter { $0.unlocked }.count
    }

    // ----------------------------------------------------
    // LOAD METHOD
    // ----------------------------------------------------
    func load(userSession: UserSession) {
        Task {
            let cachedLevels: [Level]? = AppPreferences.shared.codable([Level].self, for: .cachedLevels)
            let cachedProgress: [String: UnlockedLevelItem]? = AppPreferences.shared.codable([String: UnlockedLevelItem].self, for: .cachedProgressByLevel)

            await MainActor.run {
                self.isLoading = true

                if let cachedLevels {
                    self.levels = cachedLevels
                }

                if let cachedProgress {
                    self.updateProgressState(
                        cachedProgress,
                        sourceLevels: self.levels,
                        userSession: userSession,
                        shouldPersist: false
                    )
                } else if case .guest = userSession.state {
                    let cachedStars = AppPreferences.shared.int(for: .cachedStarCount, default: 0)
                    if cachedStars > 0 {
                        userSession.updateStarsAndLevel(stars: cachedStars, level: nil)
                    }
                }
            }

            // --- Fetch all levels ---
            let fetched = await repo.getAllLevels() ?? []
            let sorted = fetched.sorted(by: { $0.order < $1.order })

            print("🔵 HomeVM: fetched \(sorted.count) levels")

            await MainActor.run {
                if !sorted.isEmpty {
                    self.levels = sorted
                    AppPreferences.shared.setCodable(sorted, for: .cachedLevels)
                }
            }

            guard !sorted.isEmpty else {
                await MainActor.run { self.isLoading = false }
                return
            }

            // --- Progress depending on user ---
            switch userSession.state {

            case .guest:
                print("👤 HomeVM: guest user - unlocking only first level")
                if let first = sorted.first {
                    let item = UnlockedLevelItem(
                        levelId: first.id,
                        title: first.title,
                        theme: first.theme,
                        unlocked: true,
                        starsUnlocked: 0,
                        backgroundUrl: first.backgroundUrl,
                        bossUrl: first.bossUrl,
                        musicUrl: first.musicUrl
                    )
                    await MainActor.run {
                        self.updateProgressState(
                            [first.id: item],
                            sourceLevels: sorted,
                            userSession: userSession,
                            shouldPersist: true
                        )
                    }
                }

            case .loggedIn(let profile):
                print("✅ HomeVM: logged in as \(profile.name) (\(profile.id))")
                if let res = await repo.getUnlockedLevels(userId: profile.id) {
                    let map = Dictionary(
                        uniqueKeysWithValues: res.levels.map { ($0.levelId, $0) }
                    )
                    print("🔓 HomeVM: unlocked levels from backend = \(map.keys.count)")

                    await MainActor.run {
                        self.updateProgressState(
                            map,
                            sourceLevels: sorted,
                            userSession: userSession,
                            shouldPersist: true
                        )
                    }

                } else {
                    print("⚠️ HomeVM: getUnlockedLevels returned nil")
                }
            }

            await MainActor.run { self.isLoading = false }
        }
    }

    // ----------------------------------------------------
    // STATE HELPERS
    // ----------------------------------------------------
    @MainActor
    private func updateProgressState(
        _ progress: [String: UnlockedLevelItem],
        sourceLevels: [Level],
        userSession: UserSession,
        shouldPersist: Bool
    ) {
        // 1. Keep backend data exactly as-is
        let filled = completeProgressMap(progress, sourceLevels: sourceLevels)
        self.progressById = filled

        // 2. Total stars = sum of backend stars
        let totalStars = filled.values.reduce(0) { $0 + $1.starsUnlocked }

        // 3. Tell the session ONLY the star count (level order no longer matters)
        userSession.updateStarsAndLevel(
            stars: totalStars,
            level: nil
        )
    }

    // ----------------------------------------------------
    // MAP COORDINATES FOR PATH
    // ----------------------------------------------------
    func levelPoints(in size: CGSize) -> [CGPoint] {
    // Front-end only — mirror Android layout
    return levels.map { lvl in
        let pos = IOSMapPositions.positions[lvl.order] ?? CGPoint(x: 0.5, y: 0.5)
        return CGPoint(
            x: pos.x * size.width,
            y: pos.y * size.height
        )
    }
}

    
}

// MARK: - Progress Helpers
private extension HomeScreenViewModel {
    private func completeProgressMap(
    _ progress: [String: UnlockedLevelItem],
    sourceLevels: [Level]
) -> [String: UnlockedLevelItem] {

    var map = progress  // backend always wins

    // Create entries for levels backend didn’t include (rare but safe)
    for level in sourceLevels {
        if map[level.id] == nil {
            map[level.id] = UnlockedLevelItem(
                levelId: level.id,
                title: level.title,
                theme: level.theme,
                unlocked: false,
                starsUnlocked: 0,
                backgroundUrl: level.backgroundUrl,
                bossUrl: level.bossUrl,
                musicUrl: level.musicUrl
            )
        }
    }

    return map
}

}
