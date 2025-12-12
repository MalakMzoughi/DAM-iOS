//
//  AuthViewModel.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import Foundation

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    @Published var userProfile: UserProfile?
    @Published var lastAuthToken: String?
    @Published var kidFlowState: KidFlowState
    @Published var isKidFlowPresented: Bool = false

    private let authService: AuthService
    private let kidProfileStore: KidProfileStore
    private var pendingKidAuth: (token: String, profile: UserProfile)?

    // MARK: - Initializer
    init(authService: AuthService, kidProfileStore: KidProfileStore = .shared) {
        self.authService = authService
        self.kidProfileStore = kidProfileStore
        self.kidFlowState = KidFlowState(activeProfile: kidProfileStore.activeProfile())
    }

    // Factory for SwiftUI
    static func make() -> AuthViewModel {
        // We are on @MainActor here, so it's legal to call @MainActor inits
        let googleProvider = GoogleAuthProvider()
        let authService = AuthService(googleProvider: googleProvider)
        let kidStore = KidProfileStore.shared
        return AuthViewModel(authService: authService, kidProfileStore: kidStore)
    }

    // MARK: - User taps "Login with Google"
    func signInWithGoogleTapped() {
        Task {
            await signInWithGoogle()
        }
    }

    // MARK: - Main Sign-In Logic
    private func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            let (authToken, profile) = try await authService.signInWithGoogle()

            lastAuthToken = authToken
            userProfile = profile
            print("🔐 Received authToken:", authToken)

            isAuthenticated = true

        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }

        isLoading = false
    }

    // MARK: - Sign Out
    func signOutTapped() {
        authService.signOut()

        userProfile = nil
        lastAuthToken = nil
        isAuthenticated = false
        errorMessage = nil
        isLoading = false
        pendingKidAuth = nil
        kidProfileStore.clearActiveProfile()
        kidFlowState = KidFlowState()
    }

    // MARK: - Kid Flow Dialog

    func presentKidFlow() {
        kidFlowState = KidFlowState(activeProfile: kidProfileStore.activeProfile())
        kidFlowState.uniqueNameError = nil
        kidFlowState.profileError = nil
        kidFlowState.returningError = nil
        isKidFlowPresented = true
        pendingKidAuth = nil
    }

    func dismissKidFlow() {
        isKidFlowPresented = false
    }

    func showReturningKidLogin() {
        kidFlowState.step = .returningLogin
        kidFlowState.returningError = nil
    }

    func showUniqueNameStep() {
        kidFlowState.step = .uniqueName
        kidFlowState.uniqueNameError = nil
    }

    func goBackToAccountChoice() {
        kidFlowState.step = .accountChoice
        kidFlowState.uniqueNameError = nil
        kidFlowState.returningError = nil
    }

    func updateUniqueName(_ text: String) {
        kidFlowState.uniqueName = sanitizeUniqueName(text)
        kidFlowState.uniqueNameError = nil
    }

    func updateReturningUniqueName(_ text: String) {
        kidFlowState.returningUniqueName = sanitizeUniqueName(text)
        kidFlowState.returningError = nil
    }

    func updateKidName(_ text: String) {
        kidFlowState.kidName = String(text.prefix(24))
        kidFlowState.profileError = nil
    }

    func updateKidAge(_ text: String) {
        let filtered = text.filter { $0.isNumber }.prefix(2)
        kidFlowState.kidAge = String(filtered)
        kidFlowState.profileError = nil
    }

    func selectAvatarOption(_ option: KidAvatarOption) {
        kidFlowState.selectedAvatar = option
    }

    func proceedFromUniqueName() {
        let trimmed = kidFlowState.uniqueName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let validation = kidProfileStore.validateUniqueName(trimmed) {
            kidFlowState.uniqueNameError = validation
            return
        }
        if kidProfileStore.isNameTaken(trimmed, ignoring: kidFlowState.activeProfile) {
            kidFlowState.uniqueNameError = "That magic name is already taken."
            return
        }
        kidFlowState.uniqueNameError = nil
        kidFlowState.uniqueName = trimmed
        if kidFlowState.kidName.isEmpty {
            kidFlowState.kidName = prettifyName(from: trimmed)
        }
        kidFlowState.step = .profileDetails
    }

    func saveKidProfileTapped() {
        guard let profile = buildKidProfile() else { return }
        Task { await loginKid(profile: profile, fromReturningStep: false) }
    }

    func loginExistingKid() {
        let trimmed = kidFlowState.returningUniqueName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            kidFlowState.returningError = "Enter your magic name."
            return
        }
        guard let stored = kidProfileStore.profile(named: trimmed) else {
            kidFlowState.returningError = "We can't find that name."
            return
        }
        kidFlowState.returningError = nil
        Task { await loginKid(profile: stored, fromReturningStep: true) }
    }

    func handleKidGreetingContinue() {
        guard let pendingKidAuth else {
            isKidFlowPresented = false
            return
        }
        lastAuthToken = pendingKidAuth.token
        userProfile = pendingKidAuth.profile
        isAuthenticated = true
        self.pendingKidAuth = nil
        isKidFlowPresented = false
    }

    func changeKidProfile() {
        if let active = kidFlowState.activeProfile {
            kidProfileStore.release(active.uniqueName)
        }
        kidProfileStore.clearActiveProfile()
        pendingKidAuth = nil
        kidFlowState = KidFlowState()
    }

    // MARK: - Kid Flow Helpers

    private func buildKidProfile() -> KidProfile? {
        let trimmedUnique = kidFlowState.uniqueName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedUnique.isEmpty {
            kidFlowState.uniqueNameError = "Pick a magic name."
            kidFlowState.step = .uniqueName
            return nil
        }
        if let validation = kidProfileStore.validateUniqueName(trimmedUnique) {
            kidFlowState.uniqueNameError = validation
            kidFlowState.step = .uniqueName
            return nil
        }
        if kidProfileStore.isNameTaken(trimmedUnique, ignoring: kidFlowState.activeProfile) {
            kidFlowState.uniqueNameError = "That magic name is already taken."
            kidFlowState.step = .uniqueName
            return nil
        }

        guard let ageValue = Int(kidFlowState.kidAge), (3...15).contains(ageValue) else {
            kidFlowState.profileError = "Age must be between 3 and 15."
            return nil
        }

        let trimmedName = kidFlowState.kidName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmedName.isEmpty ? prettifyName(from: trimmedUnique) : trimmedName

        return KidProfile(
            uniqueName: trimmedUnique,
            displayName: displayName,
            age: ageValue,
            avatarEmoji: kidFlowState.selectedAvatar.emoji,
            avatarColorHex: kidFlowState.selectedAvatar.colorHex,
            backendAvatarId: kidFlowState.backendAvatarId,
            backendAvatarName: kidFlowState.backendAvatarName,
            backendAvatarImageUrl: kidFlowState.backendAvatarImageUrl
        )
    }

    private func loginKid(profile: KidProfile, fromReturningStep: Bool) async {
        kidFlowState.isSavingProfile = true
        defer { kidFlowState.isSavingProfile = false }

        do {
            let alias = kidProfileStore.buildAlias(for: profile.uniqueName)
            let (token, backendProfile) = try await authService.signInWithDevAccount(email: alias, name: profile.displayName)
            pendingKidAuth = (token, backendProfile)
            kidProfileStore.save(profile, setActive: true)
            kidFlowState.activeProfile = profile
            kidFlowState.uniqueName = profile.uniqueName
            kidFlowState.kidName = profile.displayName
            kidFlowState.kidAge = profile.age > 0 ? "\(profile.age)" : ""
            kidFlowState.selectedAvatar = KidAvatarOption.option(for: profile)
            kidFlowState.backendAvatarId = profile.backendAvatarId
            kidFlowState.backendAvatarName = profile.backendAvatarName
            kidFlowState.backendAvatarImageUrl = profile.backendAvatarImageUrl
            kidFlowState.profileError = nil
            kidFlowState.returningError = nil
            kidFlowState.step = .greeting
        } catch {
            if fromReturningStep {
                kidFlowState.returningError = error.localizedDescription
            } else {
                kidFlowState.profileError = error.localizedDescription
            }
        }
    }

    private func sanitizeUniqueName(_ input: String) -> String {
        let allowed = input.filter { $0.isLetter || $0.isNumber || $0 == "_" }
        return String(allowed.prefix(18))
    }

    private func prettifyName(from uniqueName: String) -> String {
        guard let first = uniqueName.first else { return uniqueName }
        return first.uppercased() + uniqueName.dropFirst().lowercased()
    }
}
