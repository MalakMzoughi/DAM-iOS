//
//  AvatarImageView.swift
//  DAM-iOS
//
//  Reusable component for displaying avatar images from URLs
//

import SwiftUI

struct AvatarImageView: View {
    let avatarUrl: String?
    let size: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    
    @State private var isLoading = true
    
    init(
        avatarUrl: String?,
        size: CGFloat = 60,
        borderColor: Color = .blue,
        borderWidth: CGFloat = 2
    ) {
        self.avatarUrl = avatarUrl
        self.size = size
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }
    
    var body: some View {
        ZStack {
            if let urlString = avatarUrl,
               let url = URL(string: getImageURL(from: urlString)) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        loadingView
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                            .onAppear {
                                isLoading = false
                            }
                    case .failure:
                        fallbackAvatar
                    @unknown default:
                        fallbackAvatar
                    }
                }
            } else {
                fallbackAvatar
            }
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(borderColor, lineWidth: borderWidth))
    }
    
    private var loadingView: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
            ProgressView()
                .scaleEffect(0.8)
        }
    }
    
    private var fallbackAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.rainbowBlue.opacity(0.3), AppColors.rainbowIndigo.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private func getImageURL(from urlString: String) -> String {
        // If it's already a full HTTP URL, return as is
        if urlString.hasPrefix("http") {
            // If it's a GLB file, convert to PNG render URL
            if urlString.hasSuffix(".glb") {
                return ReadyPlayerMeConfig.getRenderURL(avatarUrl: urlString)
            }
            return urlString
        }
        
        // Otherwise, generate the render URL
        return ReadyPlayerMeConfig.getRenderURL(avatarUrl: urlString)
    }
}

struct AvatarImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // With avatar URL
            AvatarImageView(
                avatarUrl: "https://models.readyplayer.me/64bfa15f0e72c63d7c3f5a5e.glb",
                size: 120,
                borderColor: .red
            )
            
            // Without avatar (fallback)
            AvatarImageView(
                avatarUrl: nil,
                size: 120,
                borderColor: .blue
            )
            
            // Small size
            AvatarImageView(
                avatarUrl: "https://models.readyplayer.me/64bfa15f0e72c63d7c3f5a5e.glb",
                size: 60,
                borderColor: .green
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

