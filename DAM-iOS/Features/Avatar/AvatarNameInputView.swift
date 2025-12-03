//
//  AvatarNameInputView.swift
//  DAM-iOS
//
//  Avatar creation with Ready Player Me integration - FIXED VERSION
//

import SwiftUI

struct AvatarNameInputView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: UserSession
    
    @State private var avatarName: String = ""
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showReadyPlayerMe = false
    @State private var readyPlayerMeUrl: String?
    @State private var hasAvatarBeenCustomized = false
    
    // Flow state
    @State private var currentStep: AvatarCreationStep = .nameEntry
    @State private var showAIPrompt = false
    @State private var showAIPreview = false
    @State private var showNameError = false
    
    // AI Avatar state
    @StateObject private var avatarViewModel = AvatarViewModel()
    
    enum AvatarCreationStep {
        case nameEntry
        case optionSelection
        case readyPlayerMe
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [AppColors.skyBlue, AppColors.oceanLight, AppColors.oceanDeep],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                
                switch currentStep {
                case .nameEntry:
                    avatarNameEntryView()
                case .optionSelection:
                    avatarTypeSelectionView()
                case .readyPlayerMe:
                    readyPlayerMeCreationView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        handleBackNavigation()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text(currentStep == .nameEntry ? "Close" : "Back")
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
        }
        .overlay {
            // AI Avatar Prompt Dialog
            if showAIPrompt {
                AIAvatarPromptDialog(
                    avatarName: effectiveAvatarName,
                    onGenerateAvatar: { prompt, style in
                        print("🎨 Generating AI avatar with prompt: \(prompt)")
                        avatarViewModel.generateAvatarFromPrompt(
                            prompt: prompt,
                            name: effectiveAvatarName,
                            style: style
                        )
                    },
                    onBack: {
                        showAIPrompt = false
                        currentStep = .optionSelection
                    },
                    onDismiss: {
                        showAIPrompt = false
                        currentStep = .optionSelection
                    },
                    isLoading: avatarViewModel.isGeneratingAI,
                    error: avatarViewModel.generationError
                )
                .transition(.opacity)
                .onChange(of: avatarViewModel.generatedAvatarPreview) { preview in
                    if preview != nil {
                        showAIPrompt = false
                        showAIPreview = true
                    }
                }
            }
            
            // AI Avatar Preview Dialog
            if showAIPreview, let preview = avatarViewModel.generatedAvatarPreview {
                AIAvatarPreviewSheet(
                    avatarName: effectiveAvatarName,
                    generationResponse: preview,
                    onSave: {
                        print("💾 Saving AI avatar...")
                        avatarViewModel.saveAIGeneratedAvatar(
                            previewData: preview.previewData,
                            avatarName: effectiveAvatarName
                        )
                    },
                    onRegenerate: {
                        showAIPreview = false
                        showAIPrompt = true
                        avatarViewModel.clearGeneratedPreview()
                    },
                    onDismiss: {
                        showAIPreview = false
                        avatarViewModel.clearGeneratedPreview()
                        currentStep = .optionSelection
                    },
                    isSaving: avatarViewModel.isSavingAI
                )
                .transition(.opacity)
                .onChange(of: avatarViewModel.avatars) { avatars in
                    // Avatar was saved successfully
                    if !avatarViewModel.isSavingAI && avatarViewModel.generatedAvatarPreview == nil {
                        showAIPreview = false
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showReadyPlayerMe) {
            ReadyPlayerMeView(
                onAvatarCreated: { avatarUrl in
                    print("✅ Avatar received from RPM: \(avatarUrl)")
                    readyPlayerMeUrl = avatarUrl
                    hasAvatarBeenCustomized = true
                    showReadyPlayerMe = false
                },
                existingAvatarUrl: readyPlayerMeUrl
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            avatarViewModel.setUserSession(session)
        }
        .onChange(of: avatarViewModel.activeAvatar) { newAvatar in
            if let avatar = newAvatar {
                session.setActiveAvatar(avatar)
            }
        }
    }
    
    // MARK: - Name Entry
    @ViewBuilder
    private func avatarNameEntryView() -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)
            Text("Name Your Avatar")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Start by choosing a unique name. You'll pick how to create the avatar next.")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            VStack(alignment: .leading, spacing: 10) {
                Text("Avatar Name")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                TextField("Enter name...", text: $avatarName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.2)))
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onChange(of: avatarName) { _ in
                        showNameError = false
                    }
                if showNameError {
                    Text("Please enter a name to continue")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.red)
                }
            }
            .padding(.horizontal, 32)
            Button {
                continueAfterNameEntry()
            } label: {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(canContinueFromName ? AppColors.rainbowGreen : .gray.opacity(0.5)))
                    .foregroundStyle(.white)
            }
            .disabled(!canContinueFromName)
            .padding(.horizontal, 32)
            Spacer()
        }
    }
    
    // MARK: - Avatar Type Selection View
    @ViewBuilder
    private func avatarTypeSelectionView() -> some View {
        VStack(spacing: 20) {
            Text("Avatar for \"\(avatarName)\"")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 20)
            Button {
                currentStep = .nameEntry
                showNameError = false
            } label: {
                Text("Change name")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.15)))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            Text("Choose how you want to build \(avatarName)")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer().frame(height: 20)
            VStack(spacing: 20) {
                Button {
                    showAIPrompt = true
                } label: {
                    avatarOptionCard(
                        title: "AI Generated",
                        subtitle: "Describe your avatar and let AI paint it",
                        gradient: [Color.purple, Color.pink],
                        icon: "🤖"
                    )
                }
                Button {
                    currentStep = .readyPlayerMe
                    showReadyPlayerMe = true
                } label: {
                    avatarOptionCard(
                        title: "3D Customizable",
                        subtitle: "Design a Ready Player Me avatar",
                        gradient: [Color.blue, Color.cyan],
                        icon: "🎨"
                    )
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }
    
    @ViewBuilder
    private func avatarOptionCard(title: String, subtitle: String, gradient: [Color], icon: String) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                Text(icon)
                    .font(.system(size: 50))
            }
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                )
        )
    }
    
    // MARK: - Ready Player Me Creation View
    @ViewBuilder
    private func readyPlayerMeCreationView() -> some View {
        VStack(spacing: 24) {
            Text("Create \"\(avatarName)\" in 3D")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 20)
            Button {
                currentStep = .nameEntry
                showNameError = false
            } label: {
                Text("Edit name")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.15)))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [AppColors.rainbowBlue.opacity(0.3), AppColors.rainbowIndigo.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 160, height: 160)
                if let avatarUrl = readyPlayerMeUrl, hasAvatarBeenCustomized {
                    let renderUrl = ReadyPlayerMeConfig.getRenderURL(avatarUrl: avatarUrl)
                    AsyncImage(url: URL(string: renderUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(AppColors.rainbowBlue, lineWidth: 4))
                        case .empty:
                            ProgressView().tint(.white)
                        case .failure:
                            placeholderAvatar
                        @unknown default:
                            placeholderAvatar
                        }
                    }
                } else {
                    placeholderAvatar
                }
                if hasAvatarBeenCustomized {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                                .background(Circle().fill(AppColors.rainbowGreen))
                                .offset(x: -10, y: -10)
                        }
                    }
                    .frame(width: 160, height: 160)
                }
            }
            Button {
                showReadyPlayerMe = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: hasAvatarBeenCustomized ? "paintbrush.fill" : "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(hasAvatarBeenCustomized ? "Edit Avatar" : "Customize Avatar")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(hasAvatarBeenCustomized ? AppColors.rainbowOrange : AppColors.rainbowBlue)
                )
            }
            .padding(.horizontal, 24)
            Button {
                Task { await createAvatar() }
            } label: {
                ZStack {
                    if isCreating {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Avatar")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isButtonEnabled ? AppColors.rainbowGreen : .gray.opacity(0.5))
                )
                .foregroundStyle(.white)
            }
            .disabled(!isButtonEnabled || isCreating)
            .padding(.horizontal, 24)
            if !hasAvatarBeenCustomized {
                statusMessage(text: "Customize your avatar before saving", icon: "arrow.up.circle.fill", color: AppColors.rainbowYellow)
            } else if !isButtonEnabled {
                statusMessage(text: "Missing avatar preview. Re-open Ready Player Me.", icon: "exclamationmark.circle.fill", color: AppColors.rainbowYellow)
            } else {
                statusMessage(text: "Ready to save!", icon: "checkmark.circle.fill", color: AppColors.rainbowGreen)
            }
            Spacer()
        }
        .padding(.top, 40)
    }
    
    private func statusMessage(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(color)
    }
    
    private var placeholderAvatar: some View {
        Image(systemName: "person.fill.questionmark")
            .font(.system(size: 60))
            .foregroundStyle(.white.opacity(0.5))
    }
    
    private var isButtonEnabled: Bool {
        let enabled = !avatarName.isEmpty && hasAvatarBeenCustomized && readyPlayerMeUrl != nil
        print("🔍 isButtonEnabled check:")
        print("   - avatarName.isEmpty: \(!avatarName.isEmpty)")
        print("   - hasAvatarBeenCustomized: \(hasAvatarBeenCustomized)")
        print("   - readyPlayerMeUrl != nil: \(readyPlayerMeUrl != nil)")
        print("   - Result: \(enabled)")
        return enabled
    }

    private var trimmedAvatarName: String {
        avatarName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var canContinueFromName: Bool {
        !trimmedAvatarName.isEmpty
    }
    
    private var effectiveAvatarName: String {
        canContinueFromName ? trimmedAvatarName : "MyAvatar"
    }
    
    private func createAvatar() async {
        print("\n🚀 ========== CREATE AVATAR STARTED ==========")
        
        // Validate inputs
        guard let authToken = session.authToken else {
            errorMessage = "You must be logged in to create an avatar"
            showError = true
            print("❌ No authToken found")
            return
        }
        
        guard let providerId = session.providerId else {
            errorMessage = "Provider ID not found. Please login again."
            showError = true
            print("❌ No providerId found")
            return
        }
        
        guard let avatarUrl = readyPlayerMeUrl else {
            errorMessage = "Please customize your avatar first"
            showError = true
            print("❌ No readyPlayerMeUrl found")
            return
        }
        
        guard !avatarName.isEmpty else {
            errorMessage = "Please enter an avatar name"
            showError = true
            print("❌ Avatar name is empty")
            return
        }
        
        guard hasAvatarBeenCustomized else {
            errorMessage = "Please customize your avatar first"
            showError = true
            print("❌ hasAvatarBeenCustomized is false")
            return
        }
        
        print("✅ All validations passed")
        print("📋 Avatar name: \(avatarName)")
        print("📋 Avatar URL: \(avatarUrl)")
        print("👤 Provider ID: \(providerId)")
        print("🔑 Auth Token: \(authToken.prefix(20))...")
        
        await MainActor.run {
            isCreating = true
        }
        
        defer {
            Task { @MainActor in
                isCreating = false
            }
        }
        
        do {
            // Extract avatar ID and generate URLs
            let avatarId = ReadyPlayerMeConfig.extractAvatarId(from: avatarUrl)
            print("🆔 Extracted avatar ID: \(avatarId)")
            
            let glbUrl: String = avatarUrl.hasSuffix(".glb") ? avatarUrl : "https://models.readyplayer.me/\(avatarId).glb"
            let thumbnailUrl = ReadyPlayerMeConfig.getRenderURL(avatarUrl: glbUrl)
            
            print("🖼️ Thumbnail URL: \(thumbnailUrl)")
            print("📦 GLB URL: \(glbUrl)")
            
            // Create request with image URL
            let createRequest = CreateAvatarRequest(
                name: avatarName,
                customization: nil,
                avatarImageUrl: thumbnailUrl, // This is the image URL that will be saved
                readyPlayerMeId: avatarId,
                readyPlayerMeAvatarUrl: glbUrl,
                readyPlayerMeGlbUrl: glbUrl,
                readyPlayerMeThumbnailUrl: thumbnailUrl
            )
            
            print("📤 Sending create avatar request...")
            let newAvatar = try await AvatarAPI.createAvatar(createRequest, authToken: authToken, providerId: providerId)
            print("✅ Avatar created successfully!")
            print("   - ID: \(newAvatar.id)")
            print("   - Name: \(newAvatar.name)")
            print("   - Image URL: \(newAvatar.avatarImageUrl ?? "none")")
            print("   - Is Active: \(newAvatar.isActive)")
            
            // Set as active if not already active
            if !newAvatar.isActive {
                print("📤 Setting avatar as active...")
                let activeAvatar = try await AvatarAPI.setActiveAvatar(newAvatar.id, authToken: authToken, providerId: providerId)
                await MainActor.run {
                    session.setActiveAvatar(activeAvatar)
                }
                print("✅ Avatar set as active")
            } else {
                await MainActor.run {
                    session.setActiveAvatar(newAvatar)
                }
                print("✅ Avatar is already active")
            }
            
            // Save to local storage
            UserDefaultsService.shared.saveAvatarThumbnail(thumbnailUrl)
            UserDefaultsService.shared.saveAvatarURL(glbUrl)
            UserDefaultsService.shared.saveAvatarGLB(glbUrl)
            UserDefaultsService.shared.completeAvatarSetup(avatarId: avatarId)
            
            print("💾 Avatar saved to local storage")
            print("🚀 ========== CREATE AVATAR COMPLETED ==========\n")
            
            // Dismiss the view
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("❌ ========== CREATE AVATAR FAILED ==========")
            print("❌ Error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("❌ URL Error code: \(urlError.code.rawValue)")
                print("❌ URL Error: \(urlError.localizedDescription)")
            }
            print("❌ ==========================================\n")
            
            await MainActor.run {
                errorMessage = "Failed to create avatar: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    // MARK: - Helper Methods
    private func continueAfterNameEntry() {
        guard canContinueFromName else {
            showNameError = true
            return
        }
        avatarName = trimmedAvatarName
        showNameError = false
        currentStep = .optionSelection
    }
    
    private func handleBackNavigation() {
        switch currentStep {
        case .nameEntry:
            dismiss()
        case .optionSelection:
            currentStep = .nameEntry
            showNameError = false
        case .readyPlayerMe:
            resetReadyPlayerMeState()
            currentStep = .optionSelection
        }
        showAIPrompt = false
        showAIPreview = false
    }
    
    private func resetReadyPlayerMeState() {
        readyPlayerMeUrl = nil
        hasAvatarBeenCustomized = false
        showReadyPlayerMe = false
        isCreating = false
    }
    
}

struct AvatarNameInputView_Previews: PreviewProvider {
    static var previews: some View {
        AvatarNameInputView()
            .environmentObject(UserSession())
    }
}
