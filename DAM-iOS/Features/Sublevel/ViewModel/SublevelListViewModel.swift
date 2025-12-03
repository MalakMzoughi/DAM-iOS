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

        if let userId, !userId.isEmpty,
           let enriched = await progressRepo.getUserSublevels(userId: userId, levelId: levelId) {
            sublevels = enriched.sorted { $0.index < $1.index }
            return
        }

        if let result = await repo.getSublevelsByLevel(levelId) {
            sublevels = result.sorted { $0.index < $1.index }
            return
        }

        errorMessage = "Failed to load sublevels"
        sublevels = []
    }
}
