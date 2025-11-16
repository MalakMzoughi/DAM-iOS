//
//  AvatarSelectionViewModel.swift
//  DAM-iOS
//
//  ViewModel for Avatar Selection Screen
//  Created by Apple Esprit on 13/11/2025
//

import Foundation
import Combine

class AvatarSelectionViewModel: ObservableObject {
    @Published var availableAvatars: [Avatar] = []
    @Published var selectedAvatar: Avatar? = nil
    @Published var useDefaultAvatar: Bool = true
    @Published var showPianoView = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    @MainActor func loadAvatars(userSession: UserSession) {
        isLoading = true
        
        // If user is logged in, try to fetch their avatars
        if case .loggedIn = userSession.state,
           let authToken = userSession.authToken,
           let providerId = userSession.providerId {
            
            Task {
                do {
                    let avatars = try await AvatarAPI.getUserAvatars(authToken: authToken, providerId: providerId)
                    await MainActor.run {
                        self.availableAvatars = avatars
                        self.isLoading = false
                        
                        // If user has an active avatar, pre-select it
                        if let activeAvatar = userSession.activeAvatar,
                           avatars.contains(where: { $0.id == activeAvatar.id }) {
                            self.selectedAvatar = activeAvatar
                            self.useDefaultAvatar = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        print("⚠️ Failed to load avatars: \(error.localizedDescription)")
                        self.availableAvatars = []
                        self.isLoading = false
                        // Continue with default avatar option
                    }
                }
            }
        } else {
            // Guest user - no avatars available, use default
            isLoading = false
            useDefaultAvatar = true
        }
    }
    
    func selectAvatar(_ avatar: Avatar?) {
        if let avatar = avatar {
            selectedAvatar = avatar
            useDefaultAvatar = false
        } else {
            selectedAvatar = nil
            useDefaultAvatar = true
        }
    }
    
    @MainActor func confirmSelection(userSession: UserSession) {
        // If user selected an avatar, save it to database and set as active
        if let avatar = selectedAvatar {
            // Save to database if user is logged in
            if case .loggedIn = userSession.state,
               let authToken = userSession.authToken,
               let providerId = userSession.providerId {
                
                Task {
                    do {
                        print("🔄 Setting avatar as active in database: \(avatar.name)")
                        // Set the avatar as active in the database
                        let activeAvatar = try await AvatarAPI.setActiveAvatar(avatar.id, authToken: authToken, providerId: providerId)
                        
                        await MainActor.run {
                            // Update the session with the active avatar from database
                            userSession.setActiveAvatar(activeAvatar)
                            print("✅ Avatar set as active: \(activeAvatar.name)")
                            
                            // Navigate to piano view
                            showPianoView = true
                        }
                    } catch {
                        await MainActor.run {
                            print("❌ Failed to set avatar as active: \(error.localizedDescription)")
                            // Still set locally and continue
                            userSession.setActiveAvatar(avatar)
                            errorMessage = "Failed to save avatar selection, but continuing anyway"
                            
                            // Navigate to piano view anyway
                            showPianoView = true
                        }
                    }
                }
            } else {
                // Guest user - just set locally
                userSession.setActiveAvatar(avatar)
                showPianoView = true
            }
        } else {
            // Using default avatar - clear active avatar
            userSession.setActiveAvatar(nil)
            // Navigate to piano view
            showPianoView = true
        }
    }
}

