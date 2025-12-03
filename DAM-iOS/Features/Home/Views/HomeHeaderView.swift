//
//  HomeHeaderView.swift
//  DAM-iOS
//
//  Unified card design matching Android version
//

import SwiftUI

struct HomeHeaderView: View {
    let profile: UserProfile
    let isLoggedIn: Bool
    let totalStars: Int
    let onBackTap: () -> Void
    let onProfileTap: () -> Void
    let onAddAvatarTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // BACK BUTTON
            Button(action: onBackTap) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            // small spacing
            Spacer().frame(width: 8)

            // PROFILE
            Button(action: onProfileTap) {
                HStack(spacing: 8) {
                    avatarView

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(1)

                        if !isLoggedIn {
                            Text("Guest Mode")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            Spacer()

            if isLoggedIn {
                Button(action: onAddAvatarTap) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)

                Text("\(totalStars)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.yellow.opacity(0.2))
            .clipShape(RoundedCornerShape(radius: 12))
        }
        .padding(.horizontal, 30)      // only this horizontal padding
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedCornerShape(radius: 16))
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    }

    private var avatarView: some View {
        Group {
            if let photoUrl = profile.photoUrl {
                AsyncImage(url: photoUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                    case .failure(_), .empty:
                        defaultAvatarView
                    @unknown default:
                        defaultAvatarView
                    }
                }
            } else {
                defaultAvatarView
            }
        }
    }

    private var defaultAvatarView: some View {
        ZStack {
            LinearGradient(colors: [.orange, .pink],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .frame(width: 45, height: 45)
                .clipShape(Circle())

            Text("🎹")
                .font(.system(size: 24))
        }
    }
}


// Custom rounded corner shape
struct RoundedCornerShape: Shape {
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            cornerRadius: radius
        )
        return Path(path.cgPath)
    }
}
