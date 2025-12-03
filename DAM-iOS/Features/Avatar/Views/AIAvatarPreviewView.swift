//
//  AIAvatarPreviewView.swift
//  DAM-iOS
//
//  AI Avatar preview dialog with save/regenerate options
//

import SwiftUI

struct AIAvatarPreviewView: View {
    let avatarName: String
    let generationResponse: AvatarGenerationResponse
    let onSave: () -> Void
    let onRegenerate: () -> Void
    let onDismiss: () -> Void
    let isSaving: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("🎨 Your AI Avatar")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Avatar Image - Big Rectangle
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                            .frame(height: 400)
                            .shadow(color: .black.opacity(0.2), radius: 16)
                        
                        if let imageUrl = generationResponse.avatarImageUrl,
                           let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "667EEA")))
                                            .scaleEffect(2)
                                        
                                        Text("Loading your avatar...")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Color(hex: "667EEA"))
                                        
                                        Text("Please wait a few seconds")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(32)
                                    
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity, maxHeight: 400)
                                        .clipShape(RoundedRectangle(cornerRadius: 24))
                                    
                                case .failure(_):
                                    VStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.orange)
                                        
                                        Text("Failed to load image")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(32)
                                    
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Text("No image available")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Avatar Name & Description
                    VStack(spacing: 8) {
                        Text(avatarName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let description = generationResponse.aiGeneratedDescription {
                            Text(description)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        // Cancel Button
                        Button(action: onDismiss) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                        .disabled(isSaving)
                        
                        // Regenerate Button
                        Button(action: onRegenerate) {
                            Text("Regenerate")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.orange)
                                .cornerRadius(16)
                        }
                        .disabled(isSaving)
                        
                        // Save Button
                        Button(action: onSave) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.green)
                                    .cornerRadius(16)
                            } else {
                                Text("Save")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.green)
                                    .cornerRadius(16)
                            }
                        }
                        .disabled(isSaving)
                    }
                    .padding(.top, 16)
                }
                .padding(24)
            }
        }
    }
}
