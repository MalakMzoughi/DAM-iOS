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
    @State private var hasAvatarBeenCustomized = false // NEW: explicit flag
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [AppColors.skyBlue, AppColors.oceanLight, AppColors.oceanDeep],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Create Your Avatar")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 20)
                    
                    // Avatar Preview
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [AppColors.rainbowBlue.opacity(0.3), AppColors.rainbowIndigo.opacity(0.3)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 160, height: 160)
                        
                        if let avatarUrl = readyPlayerMeUrl, hasAvatarBeenCustomized {
                            // Show the customized avatar
                            let renderUrl = ReadyPlayerMeConfig.getRenderURL(avatarUrl: avatarUrl)
                            AsyncImage(url: URL(string: renderUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 150, height: 150)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(AppColors.rainbowBlue, lineWidth: 4)
                                        )
                                case .empty:
                                    ProgressView()
                                        .tint(.white)
                                case .failure:
                                    placeholderAvatar
                                @unknown default:
                                    placeholderAvatar
                                }
                            }
                        } else {
                            placeholderAvatar
                        }
                        
                        // Checkmark overlay when avatar is ready
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
                    
                    // Customize Button
                    Button {
                        print("🎨 Opening Ready Player Me...")
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
                    
                    // Avatar Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Avatar Name")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                        
                        TextField("Enter name...", text: $avatarName)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.2)))
                            .foregroundStyle(.white)
                            .autocorrectionDisabled()
                            .disabled(!hasAvatarBeenCustomized) // Disable until avatar is created
                            .opacity(hasAvatarBeenCustomized ? 1.0 : 0.5)
                    }
                    .padding(.horizontal, 24)
                    
                    // Create Button
                    Button {
                        print("🔘 Create button tapped")
                        print("📋 Current state:")
                        print("   - avatarName: '\(avatarName)'")
                        print("   - readyPlayerMeUrl: \(readyPlayerMeUrl ?? "nil")")
                        print("   - hasAvatarBeenCustomized: \(hasAvatarBeenCustomized)")
                        print("   - isButtonEnabled: \(isButtonEnabled)")
                        
                        Task { await createAvatar() }
                    } label: {
                        ZStack {
                            if isCreating {
                                ProgressView().tint(.white)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Create Avatar")
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
                    
                    // Status Messages
                    if !hasAvatarBeenCustomized {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 16))
                            Text("Please customize your avatar first")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.rainbowYellow)
                    } else if avatarName.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 16))
                            Text("Enter a name for your avatar")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.rainbowYellow)
                    } else if isButtonEnabled {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Ready to create!")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.rainbowGreen)
                    }
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        print("❌ Cancel tapped")
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showReadyPlayerMe) {
            // This closure is called when the sheet is DISMISSED
            print("📋 Ready Player Me sheet dismissed")
            print("   - readyPlayerMeUrl: \(readyPlayerMeUrl ?? "nil")")
            print("   - hasAvatarBeenCustomized: \(hasAvatarBeenCustomized)")
        } content: {
            ReadyPlayerMeView { avatarUrl in
                print("🎨 Avatar URL received from Ready Player Me: \(avatarUrl)")
                
                // IMPORTANT: Update state on main thread
                DispatchQueue.main.async {
                    print("✅ Setting readyPlayerMeUrl and hasAvatarBeenCustomized")
                    readyPlayerMeUrl = avatarUrl
                    hasAvatarBeenCustomized = true
                    
                    // Save to local storage immediately
                    UserDefaultsService.shared.saveAvatarThumbnail(avatarUrl)
                    
                    print("✅ State updated:")
                    print("   - readyPlayerMeUrl: \(readyPlayerMeUrl ?? "nil")")
                    print("   - hasAvatarBeenCustomized: \(hasAvatarBeenCustomized)")
                    
                    // Close the sheet after a short delay to ensure state is updated
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showReadyPlayerMe = false
                        print("📋 Closed Ready Player Me sheet")
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: showReadyPlayerMe) { newValue in
            print("📋 showReadyPlayerMe changed to: \(newValue)")
        }
        .onChange(of: readyPlayerMeUrl) { newValue in
            print("📋 readyPlayerMeUrl changed to: \(newValue ?? "nil")")
        }
        .onChange(of: hasAvatarBeenCustomized) { newValue in
            print("📋 hasAvatarBeenCustomized changed to: \(newValue)")
        }
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
            print("   - RPM Avatar URL: \(newAvatar.readyPlayerMeAvatarUrl ?? "none")")
            print("   - RPM GLB URL: \(newAvatar.readyPlayerMeGlbUrl ?? "none")")
            print("   - RPM Thumbnail URL: \(newAvatar.readyPlayerMeThumbnailUrl ?? "none")")
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
}

struct AvatarNameInputView_Previews: PreviewProvider {
    static var previews: some View {
        AvatarNameInputView()
            .environmentObject(UserSession())
    }
}
