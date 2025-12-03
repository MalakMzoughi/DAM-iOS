import SwiftUI

struct AIAvatarDetailSheet: View {
    let avatar: Avatar
    let isActive: Bool
    let onSetActive: () -> Void
    let onDelete: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer(minLength: 12)
                Text("Your AI Avatar")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                
                avatarPreview
                    .padding(.horizontal, 32)
                
                Text(avatar.name)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .lineLimit(1)
                
                if let description = avatar.customization?.style, !description.isEmpty {
                    Text(description.capitalized)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    if !isActive {
                        Button(action: onSetActive) {
                            Label("Set as Active", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.green)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                            Text("This avatar is active")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundColor(.green)
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Avatar", systemImage: "trash")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.bottom, 24)
            .background(Color(white: 0.95))
            .navigationTitle("Avatar Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onClose)
                }
            }
        }
    }
    
    private var avatarPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                .frame(height: 320)
            
            if let urlString = avatar.avatarImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    case .empty:
                        ProgressView()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
                .padding(24)
            } else {
                placeholder
            }
        }
    }
    
    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            Text("No preview available")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
        }
    }
}

#if DEBUG
#Preview {
    let sampleAvatar = Avatar(
        id: "sample",
        userId: "user",
        name: "AI Hero",
        customization: nil,
        isActive: false,
        expression: nil,
        avatarImageUrl: "https://i.ibb.co/5T4dkhG/avatar.png",
        energy: nil,
        experience: nil,
        level: nil,
        state: nil,
        outfits: nil,
        createdAt: "",
        updatedAt: "",
        readyPlayerMeId: nil,
        readyPlayerMeAvatarUrl: nil,
        readyPlayerMeGlbUrl: nil,
        readyPlayerMeThumbnailUrl: nil
    )
    AIAvatarDetailSheet(
        avatar: sampleAvatar,
        isActive: false,
        onSetActive: {},
        onDelete: {},
        onClose: {}
    )
}
#endif
