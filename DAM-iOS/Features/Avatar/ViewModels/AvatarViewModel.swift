//
//  AvatarViewModel.swift
//  DAM-iOS
//
//  ViewModel for Avatar management and AI generation
//

import Foundation
import Combine

@MainActor
class AvatarViewModel: ObservableObject {
    
    @Published var avatars: [Avatar] = []
    @Published var activeAvatar: Avatar?
    @Published var isLoading = false
    @Published var error: String?
    
    // AI Generation states
    @Published var isGeneratingAI = false
    @Published var generationError: String?
    @Published var generatedAvatarPreview: AvatarGenerationResponse?
    @Published var isSavingAI = false
    
    private let avatarService = AvatarService.shared
    private var cancellables = Set<AnyCancellable>()
    private weak var userSession: UserSession?
    
    init(userSession: UserSession? = nil) {
        self.userSession = userSession
        if userSession != nil {
            loadAvatars()
            loadActiveAvatar()
        }
    }
    
    // MARK: - Session Management
    
    func setUserSession(_ session: UserSession) {
        self.userSession = session
        loadAvatars()
        loadActiveAvatar()
    }
    
    // MARK: - Auth Helpers
    
    private var authToken: String? {
        return userSession?.authToken
    }
    
    private var providerId: String? {
        return userSession?.providerId
    }
    
    // MARK: - Load Operations
    
    func loadAvatars() {
        Task {
            isLoading = true
            error = nil
            
            do {
                avatars = try await avatarService.getUserAvatars()
                print("✅ Loaded \(avatars.count) avatars")
            } catch {
                self.error = error.localizedDescription
                print("❌ Failed to load avatars: \(error)")
            }
            
            isLoading = false
        }
    }
    
    func loadActiveAvatar() {
        Task {
            do {
                activeAvatar = try await avatarService.getActiveAvatar()
                print("✅ Loaded active avatar: \(activeAvatar?.name ?? "none")")
            } catch {
                print("❌ Failed to load active avatar: \(error)")
                // Don't set error here as it's not critical
            }
        }
    }
    
    // MARK: - Avatar CRUD
    
    func createAvatar(name: String, avatarImageUrl: String?) {
        Task {
            isLoading = true
            error = nil
            
            let createDto = CreateAvatarDto(
                name: name,
                customization: CreateAvatarCustomizationDto(
                    style: "default",
                    bodyType: "medium",
                    skinTone: "medium",
                    hairstyle: "short",
                    hairColor: "brown",
                    eyeStyle: "default",
                    eyeColor: "brown",
                    clothingType: nil,
                    clothingColor: nil,
                    accessories: nil
                ),
                avatarImageUrl: avatarImageUrl
            )
            
            do {
                let avatar = try await avatarService.createAvatar(dto: createDto)
                print("✅ Avatar created: \(avatar.name)")
                
                // Reload avatars to refresh the list
                loadAvatars()
                loadActiveAvatar()
            } catch {
                self.error = error.localizedDescription
                print("❌ Failed to create avatar: \(error)")
            }
            
            isLoading = false
        }
    }
    
    func updateAvatar(avatarId: String, dto: UpdateAvatarDto) {
        Task {
            isLoading = true
            error = nil
            
            do {
                let avatar = try await avatarService.updateAvatar(avatarId: avatarId, dto: dto)
                print("✅ Avatar updated: \(avatar.name)")
                
                // Update in local array
                if let index = avatars.firstIndex(where: { $0.id == avatarId }) {
                    avatars[index] = avatar
                }
                
                if activeAvatar?.id == avatarId {
                    activeAvatar = avatar
                }
            } catch {
                self.error = error.localizedDescription
                print("❌ Failed to update avatar: \(error)")
            }
            
            isLoading = false
        }
    }
    
    func setActiveAvatar(_ avatar: Avatar) {
        Task {
            isLoading = true
            error = nil
            
            do {
                let updatedAvatar = try await avatarService.setActiveAvatar(avatarId: avatar.id)
                print("✅ Avatar activated: \(updatedAvatar.name)")
                
                activeAvatar = updatedAvatar
                loadAvatars() // Reload to update isActive flags
            } catch {
                self.error = error.localizedDescription
                print("❌ Failed to activate avatar: \(error)")
            }
            
            isLoading = false
        }
    }
    
    func deleteAvatar(_ avatar: Avatar) {
        Task {
            isLoading = true
            error = nil
            
            do {
                _ = try await avatarService.deleteAvatar(avatarId: avatar.id)
                print("✅ Avatar deleted: \(avatar.name)")
                
                // Remove from local array
                avatars.removeAll { $0.id == avatar.id }
                
                // Reload active avatar if deleted
                if activeAvatar?.id == avatar.id {
                    loadActiveAvatar()
                }
            } catch {
                self.error = error.localizedDescription
                print("❌ Failed to delete avatar: \(error)")
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Gameplay Operations
    
    func updateExpression(avatarId: String, expression: String) {
        Task {
            do {
                let avatar = try await avatarService.updateExpression(avatarId: avatarId, expression: expression)
                if activeAvatar?.id == avatarId {
                    activeAvatar = avatar
                }
            } catch {
                print("❌ Failed to update expression: \(error)")
            }
        }
    }
    
    func addExperience(avatarId: String, xpGain: Int) {
        Task {
            do {
                let avatar = try await avatarService.addExperience(avatarId: avatarId, xpGain: xpGain)
                if activeAvatar?.id == avatarId {
                    activeAvatar = avatar
                }
                print("✅ Added \(xpGain) XP to avatar")
            } catch {
                print("❌ Failed to add experience: \(error)")
            }
        }
    }
    
    func updateEnergy(avatarId: String, energyChange: Int) {
        Task {
            do {
                let avatar = try await avatarService.updateEnergy(avatarId: avatarId, energyChange: energyChange)
                if activeAvatar?.id == avatarId {
                    activeAvatar = avatar
                }
            } catch {
                print("❌ Failed to update energy: \(error)")
            }
        }
    }
    
    // MARK: - AI Avatar Generation
    
    func generateAvatarFromPrompt(prompt: String, name: String, style: String = "cartoon") {
        Task {
            isGeneratingAI = true
            generationError = nil
            generatedAvatarPreview = nil
            
            let dto = GenerateAvatarFromPromptDto(prompt: prompt, name: name, style: style)
            
            do {
                let result = try await avatarService.generateAvatarFromPrompt(dto: dto)
                print("✅ AI avatar generated: \(result.name)")
                generatedAvatarPreview = result
            } catch {
                generationError = error.localizedDescription
                print("❌ Failed to generate AI avatar: \(error)")
            }
            
            isGeneratingAI = false
        }
    }
    
    func saveAIGeneratedAvatar(previewData: AnyCodable, avatarName: String) {
        Task {
            isSavingAI = true
            error = nil
            
            print("📤 Saving AI avatar with name: '\(avatarName)'")
            
            do {
                let result = try await avatarService.saveAIAvatar(previewData: previewData, name: avatarName)
                print("✅ AI avatar saved successfully!")
                print("   - Avatar ID: \(result.avatarId)")
                print("   - Avatar Name: \(result.name)")
                print("   - Backend returned name: \(result.avatar.name)")
                
                // Clear preview and reload avatars
                generatedAvatarPreview = nil
                activeAvatar = result.avatar
                loadAvatars()
                loadActiveAvatar()
            } catch {
                self.error = error.localizedDescription
                print("❌ Failed to save AI avatar: \(error)")
            }
            
            isSavingAI = false
        }
    }
    
    func clearGeneratedPreview() {
        generatedAvatarPreview = nil
        generationError = nil
    }
    
    func clearError() {
        error = nil
        generationError = nil
    }
}
