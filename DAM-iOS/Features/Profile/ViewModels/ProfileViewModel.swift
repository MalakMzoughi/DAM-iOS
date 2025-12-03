//
//  ProfileViewModel.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var avatars: [Avatar] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isPerformingAction: Bool = false
    
    private let avatarService = AvatarService.shared
    
    @MainActor func loadAvatars(userSession: UserSession) {
        isLoading = true
        errorMessage = nil
        
        // Only load avatars if user is logged in
        guard case .loggedIn = userSession.state,
              let authToken = userSession.authToken,
              let providerId = userSession.providerId else {
            isLoading = false
            avatars = []
            return
        }
        
        Task {
            do {
                let fetchedAvatars = try await AvatarAPI.getUserAvatars(authToken: authToken, providerId: providerId)
                await MainActor.run {
                    self.avatars = fetchedAvatars
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.avatars = []
                }
            }
        }
    }
    
    @MainActor
    func setActiveAvatar(_ avatar: Avatar, userSession: UserSession) async {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            let updatedAvatar = try await avatarService.setActiveAvatar(avatarId: avatar.id)
            userSession.setActiveAvatar(updatedAvatar)
            loadAvatars(userSession: userSession)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func deleteAvatar(_ avatar: Avatar, userSession: UserSession) async {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            _ = try await avatarService.deleteAvatar(avatarId: avatar.id)
            if userSession.activeAvatar?.id == avatar.id {
                userSession.setActiveAvatar(nil)
            }
            loadAvatars(userSession: userSession)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
