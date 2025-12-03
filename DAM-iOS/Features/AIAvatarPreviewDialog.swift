//
//  AIAvatarPreviewDialog.swift
//  DAM-iOS
//
//  AI Avatar Preview Dialog showing generated avatar
//

import SwiftUI

// MARK: - Color Extension for Hex Colors
extension Color {
    init(hex: Int, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

struct AIAvatarPreviewSheet: View {
    let avatarName: String
    let generationResponse: AvatarGenerationResponse
    let onSave: () -> Void
    let onRegenerate: () -> Void
    let onDismiss: () -> Void
    let isSaving: Bool
    
    @State private var imageLoaded = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            backgroundOverlay
            dialogContent
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
            ) {
                scale = 1.05
            }
        }
    }
    
    private var backgroundOverlay: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture {
                if !isSaving {
                    onDismiss()
                }
            }
    }
    
    private var dialogContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                headerView
                avatarImageView
                avatarNameView
                avatarInfoView
                actionButtons
            }
            .padding(24)
        }
        .frame(maxWidth: 500)
        .frame(maxHeight: UIScreen.main.bounds.height * 0.9)
        .background(gradientBackground)
        .cornerRadius(32)
        .shadow(radius: 20)
        .padding(20)
    }
    
    private var headerView: some View {
        Text("Your AI Avatar")
            .font(.system(size: 24, weight: .black))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
    }
    
    private var avatarImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .frame(height: 400)
                .shadow(radius: 16)
            
            if !imageLoaded {
                loadingView
            }
            
            if let imageUrl = generationResponse.avatarImageUrl,
               let url = URL(string: imageUrl) {
                avatarAsyncImage(url: url)
            }
        }
        .frame(height: 400)
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: 0x667EEA)))
                .scaleEffect(2)
            
            Text("Loading your avatar...")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: 0x667EEA))
            
            Text("Please wait a few seconds")
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .padding(32)
    }
    
    private func avatarAsyncImage(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                EmptyView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .onAppear {
                        imageLoaded = true
                        print("✅ Avatar image loaded successfully")
                    }
            case .failure(let error):
                errorView(error: error)
            @unknown default:
                EmptyView()
            }
        }
    }
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Failed to load image")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.gray)
            
            Text(error.localizedDescription)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .onAppear {
            print("❌ Failed to load avatar image: \(error)")
        }
    }
    
    private var avatarInfoView: some View {
        VStack(spacing: 8) {
            if let description = generationResponse.aiGeneratedDescription {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    private var avatarNameView: some View {
        VStack(spacing: 6) {
            Text("Avatar Name")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            Text("\(avatarName)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.15))
                .cornerRadius(14)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            cancelButton
            regenerateButton
            saveButton
        }
    }
    
    private var cancelButton: some View {
        Button(action: onDismiss) {
            Text("Cancel")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white.opacity(0.2))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        .disabled(isSaving)
    }
    
    private var regenerateButton: some View {
        Button(action: onRegenerate) {
            Text("Regenerate")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: 0xFFA726))
                .cornerRadius(16)
        }
        .disabled(isSaving)
    }
    
    private var saveButton: some View {
        Button(action: {
            onSave()
        }) {
            if isSaving {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            } else {
                Text("Save Avatar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(isSaving ? Color.gray : Color(hex: 0x4CAF50))
        .cornerRadius(16)
        .disabled(isSaving)
    }
    
    private var gradientBackground: some View {
        let topColor = Color(hex: 0x667EEA)
        let bottomColor = Color(hex: 0x764BA2)
        
        return LinearGradient(
            colors: [topColor, bottomColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    AIAvatarPreviewSheet(
        avatarName: "SuperKid",
        generationResponse: AvatarGenerationResponse(
            name: "SuperKid",
            description: "A superhero character",
            aiGeneratedDescription: "A brave superhero with a red cape and blue costume, ready to save the day!",
            suggestedAttributes: SuggestedAttributes(
                bodyType: "athletic",
                skinTone: "medium",
                hairstyle: "short",
                hairColor: "black",
                eyeStyle: "heroic",
                eyeColor: "blue",
                clothingType: "superhero",
                clothingColor: "blue",
                accessories: ["cape"]
            ),
            avatarImageUrl: "https://example.com/avatar.png",
            generationSource: "gemini-ai",
            previewData: AnyCodable([:])
        ),
        onSave: {},
        onRegenerate: { },
        onDismiss: { },
        isSaving: false
    )
}
