//
//  SublevelListViewModel.swift
//  DAM-iOS
//
//  ViewModel to fetch and expose sublevels for a level
//

import Foundation

@MainActor
final class SublevelListViewModel: ObservableObject {
    @Published var sublevels: [Sublevel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let repo = SublevelRepository()
    private let progressRepo = SublevelProgressRepository()

    func loadSublevels(for levelId: String, userId: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        print("🔷 SublevelListVM: loadSublevels called for levelId=\(levelId), userId=\(userId ?? "nil")")

        if let userId, !userId.isEmpty,
           let enriched = await progressRepo.getUserSublevels(userId: userId, levelId: levelId) {
            print("🔷 SublevelListVM: progress endpoint returned \(enriched.count) sublevels")
            // If backend returns an empty array for progress, fall back to base sublevels so guests/logged-in users still see missions
            if !enriched.isEmpty {
                print("✅ SublevelListVM: using progress sublevels")
                sublevels = enriched.sorted { $0.index < $1.index }
                return
            }
            print("⚠️ SublevelListVM: progress returned empty, falling back to base list")
        }

        if let result = await repo.getSublevelsByLevel(levelId) {
            print("🔷 SublevelListVM: base endpoint returned \(result.count) sublevels")
            sublevels = result.sorted { $0.index < $1.index }
            return
        }

        print("❌ SublevelListVM: both endpoints failed")
        errorMessage = "Failed to load sublevels"
        sublevels = []
    }
}
