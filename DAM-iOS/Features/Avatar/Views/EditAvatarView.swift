//
//  EditAvatarView.swift
//  DAM-iOS
//
//  View to edit an existing avatar in Ready Player Me
//

import SwiftUI

struct EditAvatarView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: UserSession
    
    let avatar: Avatar
    
    @State private var isUpdating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showReadyPlayerMe = false
    @State private var updatedAvatarUrl: String?
    @State private var saveTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [AppColors.skyBlue, AppColors.oceanLight, AppColors.oceanDeep],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Edit Avatar")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 20)
                    
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [AppColors.rainbowBlue.opacity(0.3), AppColors.rainbowIndigo.opacity(0.3)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 160, height: 160)
                        
                        if let avatarUrl = updatedAvatarUrl ?? (avatar.readyPlayerMeAvatarUrl ?? avatar.readyPlayerMeGlbUrl) {
                            AvatarImageView(avatarUrl: avatarUrl, size: 150, borderColor: AppColors.rainbowBlue, borderWidth: 4)
                        } else {
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 60))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    
                    Text(avatar.name)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Button {
                        // Open Ready Player Me with existing avatar URL if available
                        showReadyPlayerMe = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "paintbrush.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Edit in Ready Player Me")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.rainbowBlue))
                    }
                    .padding(.horizontal, 24)
                    
                    Button {
                        Task { await updateAvatar() }
                    } label: {
                        ZStack {
                            if isUpdating {
                                ProgressView().tint(.white)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Changes")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(updatedAvatarUrl != nil ? AppColors.rainbowGreen : .gray.opacity(0.5))
                        .foregroundStyle(.white)
                    }
                    .disabled(updatedAvatarUrl == nil || isUpdating)
                    .padding(.horizontal, 24)
                    
                    if updatedAvatarUrl == nil {
                        Text("Edit your avatar first to save changes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.rainbowOrange)
                    }
                    
                    if isUpdating {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text("Saving avatar...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showReadyPlayerMe) {
            ReadyPlayerMeView(
                existingAvatarUrl: avatar.readyPlayerMeAvatarUrl ?? avatar.readyPlayerMeGlbUrl
            ) { avatarUrl in
                print("🎨 Updated Avatar URL received from Ready Player Me: \(avatarUrl)")
                print("🔄 Setting updatedAvatarUrl...")
                
                // Close the Ready Player Me sheet first
                showReadyPlayerMe = false
                
                // Set the URL - onChange will trigger auto-save after a delay
                // This ensures the sheet is closed before we start saving
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    updatedAvatarUrl = avatarUrl
                }
            }
        }
        .onChange(of: updatedAvatarUrl) { newUrl in
            print("🔍 onChange triggered - newUrl: \(newUrl ?? "nil")")
            print("🔍 Current avatar URL: \(avatar.readyPlayerMeAvatarUrl ?? avatar.readyPlayerMeGlbUrl ?? "nil")")
            
            // Auto-save when URL is set
            if let newUrl = newUrl {
                let currentUrl = avatar.readyPlayerMeAvatarUrl ?? avatar.readyPlayerMeGlbUrl ?? ""
                let isDifferent = newUrl != currentUrl
                
                print("🔍 URLs are different: \(isDifferent)")
                print("🔍 New URL: \(newUrl)")
                print("🔍 Current URL: \(currentUrl)")
                
                // Always save if we have a new URL (even if it seems the same, the avatar might have been updated)
                if isDifferent || !currentUrl.isEmpty {
                    print("🔄 updatedAvatarUrl changed, triggering auto-save...")
                    print("📋 New URL: \(newUrl)")
                    
                    // Cancel any existing save task
                    saveTask?.cancel()
                    
                    // Create a new task to save
                    saveTask = Task { @MainActor in
                        print("⏳ Waiting before auto-save...")
                        // Wait a bit for state to stabilize and sheet to fully close
                        try? await Task.sleep(nanoseconds: 1500_000_000) // 1.5 seconds
                        
                        // Check if task was cancelled
                        guard !Task.isCancelled else {
                            print("⚠️ Save task was cancelled")
                            return
                        }
                        
                        // Double-check URL is still set
                        guard updatedAvatarUrl == newUrl else {
                            print("⚠️ URL changed during wait, aborting save")
                            return
                        }
                        
                        print("💾 Starting automatic avatar update...")
                        await updateAvatar()
                    }
                } else {
                    print("⚠️ Skipping save - URL is empty or same as current")
                }
            } else {
                print("⚠️ newUrl is nil, skipping save")
            }
        }
        .onDisappear {
            // Clean up task when view disappears
            saveTask?.cancel()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    @MainActor
    private func updateAvatar() async {
        print("🔄 updateAvatar() called")
        print("📋 updatedAvatarUrl value: \(updatedAvatarUrl ?? "nil")")
        print("📋 isUpdating: \(isUpdating)")
        
        // Double-check the URL is set
        guard let updatedUrl = updatedAvatarUrl else {
            print("❌ No updatedAvatarUrl found - cannot save")
            errorMessage = "No changes to save. Please edit your avatar again."
            showError = true
            return
        }
        
        print("✅ URL found: \(updatedUrl)")
        
        guard let authToken = session.authToken,
              let providerId = session.providerId else {
            print("❌ Missing auth credentials")
            errorMessage = "You must be logged in to update an avatar"
            showError = true
            return
        }
        
        print("🔄 Starting avatar update...")
        print("🔗 Updated Avatar URL: \(updatedUrl)")
        
        isUpdating = true
        defer { isUpdating = false }
        
        do {
            // Extract avatar ID and generate URLs
            let avatarId = ReadyPlayerMeConfig.extractAvatarId(from: updatedUrl)
            print("🆔 Extracted avatar ID: \(avatarId)")
            
            let glbUrl: String = updatedUrl.hasSuffix(".glb") ? updatedUrl : "https://models.readyplayer.me/\(avatarId).glb"
            let thumbnailUrl = ReadyPlayerMeConfig.getRenderURL(avatarUrl: glbUrl)
            
            print("🖼️ Thumbnail URL: \(thumbnailUrl)")
            print("📦 GLB URL: \(glbUrl)")
            
            // Update request with new URLs
            let updateRequest = UpdateAvatarRequest(
                name: nil, // Keep existing name
                customization: nil,
                expression: nil,
                energy: nil,
                state: nil,
                isActive: nil,
                avatarImageUrl: thumbnailUrl,
                readyPlayerMeId: avatarId,
                readyPlayerMeAvatarUrl: glbUrl,
                readyPlayerMeGlbUrl: glbUrl,
                readyPlayerMeThumbnailUrl: thumbnailUrl
            )
            
            // Update avatar in database
            print("📤 Sending update avatar request...")
            let updatedAvatar = try await AvatarAPI.updateAvatar(avatar.id, request: updateRequest, authToken: authToken, providerId: providerId)
            print("✅ Avatar updated successfully: \(updatedAvatar.name)")
            
            // Refresh the avatar from the server to get updated URLs
            let refreshedAvatars = try await AvatarAPI.getUserAvatars(authToken: authToken, providerId: providerId)
            if let refreshedAvatar = refreshedAvatars.first(where: { $0.id == avatar.id }) {
                print("✅ Found refreshed avatar: \(refreshedAvatar.name)")
                print("🖼️ Refreshed avatar image URL: \(refreshedAvatar.avatarImageUrl ?? "none")")
                
                // Always set this avatar as active (user wants to use it as assistant)
                print("🔄 Setting avatar as active assistant...")
                let activeAvatar = try await AvatarAPI.setActiveAvatar(refreshedAvatar.id, authToken: authToken, providerId: providerId)
                
                // Update session with the active avatar
                session.setActiveAvatar(activeAvatar)
                print("✅ Avatar set as active assistant: \(activeAvatar.name)")
                print("✅ Avatar URLs updated in database")
            } else {
                print("⚠️ Could not find refreshed avatar in list")
            }
            
            print("💾 Avatar update saved and set as active")
            
            // Dismiss the view
            dismiss()
        } catch {
            print("❌ Error updating avatar: \(error)")
            errorMessage = "Failed to update avatar: \(error.localizedDescription)"
            showError = true
        }
    }
}

