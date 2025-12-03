//
//  ProfileComponents.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI

struct AnimatedKidsBackground: View {
    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let float1 = CGFloat(sin(t / 3.0))
            let float2 = CGFloat(cos(t / 4.0))
            let float3 = CGFloat(sin(t / 2.1 + 1.2))

            Canvas { context, size in
                let largeBlob = CGRect(
                    x: size.width * 0.05,
                    y: size.height * 0.15 + float1 * 35,
                    width: size.width * 0.5,
                    height: size.width * 0.5
                )
                let mediumBlob = CGRect(
                    x: size.width * 0.55,
                    y: size.height * 0.05 + float2 * 45,
                    width: size.width * 0.35,
                    height: size.width * 0.35
                )
                let smallBlob = CGRect(
                    x: size.width * 0.3,
                    y: size.height * 0.65 + float3 * 30,
                    width: size.width * 0.25,
                    height: size.width * 0.25
                )

                let colors = [
                    Color.white.opacity(0.25),
                    Color.white.opacity(0.05)
                ]

                context.fill(
                    Path(ellipseIn: largeBlob),
                    with: .radialGradient(
                        .init(colors: colors),
                        center: .init(x: largeBlob.midX, y: largeBlob.midY),
                        startRadius: 10,
                        endRadius: largeBlob.width / 1.4
                    )
                )

                context.fill(
                    Path(ellipseIn: mediumBlob),
                    with: .radialGradient(
                        .init(colors: colors),
                        center: .init(x: mediumBlob.midX, y: mediumBlob.midY),
                        startRadius: 8,
                        endRadius: mediumBlob.width / 1.6
                    )
                )

                context.fill(
                    Path(ellipseIn: smallBlob),
                    with: .radialGradient(
                        .init(colors: colors),
                        center: .init(x: smallBlob.midX, y: smallBlob.midY),
                        startRadius: 6,
                        endRadius: smallBlob.width / 1.3
                    )
                )

                // Sparkles
                let sparkles = stride(from: 0, through: 1, by: 0.2)
                for value in sparkles {
                    let x = size.width * CGFloat(value)
                    let y = size.height * (0.2 + CGFloat(value) * 0.6)
                    let radius = CGFloat(4 + value * 8)
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: x + float1 * 10,
                            y: y + float2 * 10,
                            width: radius,
                            height: radius
                        )),
                        with: .color(Color.white.opacity(0.2 + value * 0.2))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct AnimatedProfileAvatar: View {
    let name: String
    let photoUrl: URL?
    @State private var up = false

    var body: some View {
        ZStack {
            Circle().fill(
                RadialGradient(colors: [AppColors.rainbowPink, AppColors.rainbowOrange],
                               center: .center, startRadius: 10, endRadius: 80)
            )
            .frame(width: 120, height: 120)
            .scaleEffect(up ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: up)

            if let url = photoUrl {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: { Color.white.opacity(0.3) }
                .clipShape(Circle())
                .frame(width: 120, height: 120)
            } else {
                Text(String(name.prefix(2)).uppercased())
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .onAppear { up = true }
    }
}

struct ProviderBadge: View {
    let provider: String
    var body: some View {
        let color: Color = {
            switch provider.lowercased() {
            case "google": return Color(hex: 0x4285F4)
            case "facebook": return Color(hex: 0x1877F2)
            case "apple": return .black
            default: return .gray
            }
        }()
        return Text(String(provider.prefix(1)).uppercased())
            .font(.system(size: 14, weight: .bold))
            .padding(8)
            .background(color, in: Circle())
            .foregroundStyle(.white)
    }
}

struct StatsCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(icon).font(.system(size: 28))
            Text(title).font(.caption).foregroundStyle(AppColors.textLight)
            Text(value).font(.system(size: 20, weight: .bold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppColors.cardBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}

struct AchievementsSection: View {
    let totalStars: Int
    let maxStars: Int
    var body: some View {
        VStack(spacing: 8) {
            Text("Achievements").font(.title3.bold()).foregroundStyle(.white)
            HStack(spacing: 8) {
                let earned = totalStars / max(1, maxStars/3)
                ForEach(0..<3) { i in
                    Image(systemName: "star.fill")
                        .foregroundStyle(i < earned ? AppColors.rainbowYellow : .gray)
                        .font(.system(size: 28))
                }
            }
        }
    }
}

struct AccountInfoCard: View {
    let profile: UserProfile
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Info")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColors.rainbowBlue)

            infoRow(icon: "person", label: "Name", value: profile.name)
            infoRow(icon: "envelope", label: "Email", value: profile.email ?? "No email (Guest mode)")
            if !profile.provider.isEmpty {
                infoRow(icon: "lock", label: "Login Method", value: profile.provider.capitalized)
            }
            let progress = Int(Double(profile.totalStars) / Double(max(1, profile.maxStars)) * 100)
            infoRow(icon: "star.fill", label: "Progress", value: "\(progress)%")
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading )
        .background(AppColors.cardBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    @ViewBuilder
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(AppColors.rainbowBlue).frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(AppColors.textLight)
                Text(value).font(.body.weight(.medium))
            }
        }
    }
}

// MARK: - My Avatars Section
struct MyAvatarsSection: View {
    let avatars: [Avatar]
    let isLoading: Bool
    let activeAvatar: Avatar?
    var onAvatarTap: ((Avatar) -> Void)? = nil
    var onActivateAvatar: ((Avatar) -> Void)? = nil
    var onDeleteAvatar: ((Avatar) -> Void)? = nil
    var onCreateAvatarTap: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Avatars")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()
                
                if onCreateAvatarTap != nil {     // 👈 show only if handler provided
                    Button(action: {
                        onCreateAvatarTap?()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("New Avatar")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Color.white.opacity(0.2),
                            in: Capsule()
                        )
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if avatars.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("No avatars created yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    // Optional: extra CTA in empty state
                    if onCreateAvatarTap != nil {
                        Button(action: {
                            onCreateAvatarTap?()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle")
                                Text("Create your first avatar")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Color.white.opacity(0.25),
                                in: Capsule()
                            )
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(avatars) { avatar in
                            AvatarProfileCard(
                                avatar: avatar,
                                isActive: activeAvatar?.id == avatar.id,
                                onPreview: onAvatarTap != nil ? { onAvatarTap?(avatar) } : nil,
                                onActivate: onActivateAvatar != nil ? { onActivateAvatar?(avatar) } : nil,
                                onDelete: onDeleteAvatar != nil ? { onDeleteAvatar?(avatar) } : nil
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}


// MARK: - Avatar Profile Card
struct AvatarProfileCard: View {
    let avatar: Avatar
    let isActive: Bool
    var onPreview: (() -> Void)? = nil
    var onActivate: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.rainbowPink.opacity(0.3),
                                AppColors.rainbowOrange.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(isActive ? Color.yellow : Color.white.opacity(0.5), lineWidth: isActive ? 4 : 2)
                    )
                avatarImage
            }
            .onTapGesture {
                onPreview?()
            }
            .accessibilityAddTraits(.isButton)
            
            Text(avatar.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            
            if isActive {
                badgeView(text: "Active", color: .yellow)
            }
            
            HStack(spacing: 8) {
                if let onActivate = onActivate, !isActive {
                    Button(action: onActivate) {
                        Label("Set Active", systemImage: "checkmark.circle")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .foregroundColor(.white)
                    .background(Color.green.opacity(0.3), in: Capsule())
                    .buttonStyle(.plain)
                }
                
                if let onDelete = onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .bold))
                            .padding(8)
                    }
                    .foregroundColor(.white)
                    .background(Color.red.opacity(0.25), in: Circle())
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 160)
        .padding(12)
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    private var avatarImage: some View {
        Group {
            if let imageUrl = avatar.avatarImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    case .empty:
                        ProgressView()
                            .tint(.white)
                            .frame(width: 100, height: 100)
                    case .failure:
                        fallbackAvatarImage
                    @unknown default:
                        fallbackAvatarImage
                    }
                }
            } else {
                fallbackAvatarImage
            }
        }
    }
    
    private var fallbackAvatarImage: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 100, height: 100)
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    private func badgeView(text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2), in: Capsule())
    }
}

// MARK: - New Kids-Themed Components (Android parity)

struct FunTopBar: View {
    var onNavigateBack: () -> Void
    var onSettings: () -> Void
    var onLogout: (() -> Void)?
    var onMusic: (() -> Void)?

    var body: some View {
        HStack {
            BouncyButton(onClick: onNavigateBack,
                         backgroundColor: .white.opacity(0.95),
                         borderColor: .white) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColors.rainbowBlue)
            }

            Spacer()

            HStack(spacing: 12) {
                if let onMusic = onMusic {
                    BouncyButton(onClick: onMusic,
                                 backgroundColor: Color.white.opacity(0.85),
                                 borderColor: .white) {
                        Text("🎵")
                            .font(.system(size: 24))
                    }
                }

                BouncyButton(onClick: onSettings,
                             backgroundColor: Color(hex: 0xFFFDEB9D),
                             borderColor: .white) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppColors.rainbowBlue)
                }

                if let onLogout = onLogout {
                    BouncyButton(onClick: onLogout,
                                 backgroundColor: Color(hex: 0xFFFFA3B1),
                                 borderColor: .white) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppColors.rainbowRed)
                    }
                }
            }
        }
    }
}

struct BouncyButton<Content: View>: View {
    var onClick: () -> Void
    var backgroundColor: Color
    var borderColor: Color
    @ViewBuilder var content: () -> Content

    @State private var isPressed = false

    var body: some View {
        Button {
            isPressed = true
#if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
#endif
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
            onClick()
        } label: {
            content()
                .frame(width: 56, height: 56)
                .background(backgroundColor, in: Circle())
                .overlay(
                    Circle()
                        .stroke(borderColor.opacity(0.8), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.88 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: isPressed)
    }
}

struct PlayfulProfileAvatar: View {
    let avatarURL: URL?
    let initials: String
    var onTap: (() -> Void)? = nil

    @State private var rotation: Double = 0
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(hex: 0xFF6FD8),
                            Color(hex: 0xFDB9FC),
                            Color(hex: 0xFFEEA2),
                            Color(hex: 0xFF6FD8)
                        ]),
                        center: .center
                    ),
                    lineWidth: 12
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(rotation))
                .animation(.linear(duration: 18).repeatForever(autoreverses: false), value: rotation)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0)],
                        center: .center,
                        startRadius: 20,
                        endRadius: 140
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(pulse ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulse)

            avatarContent
        }
        .onTapGesture {
            onTap?()
        }
        .onAppear {
            rotation = 360
            pulse = true
        }
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let avatarURL {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ProgressView()
                case .failure:
                    Text(initials)
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(.white)
                @unknown default:
                    Text(initials)
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 160, height: 160)
            .background(Color.white.opacity(0.15))
            .clipShape(Circle())
        } else {
            Text(initials)
                .font(.system(size: 64, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 160, height: 160)
                .background(
                    LinearGradient(colors: [
                        Color(hex: 0xFF9A9E),
                        Color(hex: 0xFAD0C4)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Circle()
                )
        }
    }
}

struct KidsNameSection: View {
    let userName: String
    let provider: String
    var onEdit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hi there!")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))

            HStack(alignment: .center, spacing: 12) {
                Text(userName)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if !provider.isEmpty {
                    FunProviderBadge(provider: provider)
                }

                Spacer()

                if let onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 48, height: 48)
                            .background(Color.white, in: Circle())
                            .foregroundStyle(AppColors.rainbowBlue)
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(colors: [
                        Color(hex: 0xFFFDEB9D),
                        Color(hex: 0xFFF093FB)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 3
                )
        )
    }
}

struct FunProviderBadge: View {
    let provider: String

    var body: some View {
        let color: Color = {
            switch provider.lowercased() {
            case "google": return Color(hex: 0x4285F4)
            case "facebook": return Color(hex: 0x1877F2)
            case "apple": return .black
            default: return Color.white.opacity(0.3)
            }
        }()

        return Text(provider.prefix(1).uppercased())
            .font(.system(size: 16, weight: .bold))
            .padding(8)
            .background(color, in: Circle())
            .foregroundStyle(.white)
    }
}

struct KidsLevelBadge: View {
    let userLevel: Int

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let shimmer = 0.8 + 0.2 * sin(t)

            HStack(spacing: 16) {
                Text(levelEmoji(userLevel))
                    .font(.system(size: 42))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Level")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))

                    Text(levelTitle(userLevel))
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("Lv. \(userLevel)")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2), in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(shimmer), lineWidth: 2)
                    )
            }
            .padding()
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(colors: [
                            Color(hex: 0x7F7FD5),
                            Color(hex: 0x86A8E7)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2
                    )
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func levelTitle(_ level: Int) -> String {
        switch level {
        case 1: return "Beginner"
        case 2...3: return "Learner"
        case 4...5: return "Player"
        case 6...7: return "Skilled"
        case 8...10: return "Expert"
        default: return "Master"
        }
    }

    private func levelEmoji(_ level: Int) -> String {
        switch level {
        case 1: return "🎹"
        case 2...3: return "🎶"
        case 4...5: return "🎵"
        case 6...7: return "⭐️"
        case 8...10: return "🏆"
        default: return "👑"
        }
    }
}

struct GuestModeBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("🎮")
                .font(.system(size: 32))
            VStack(alignment: .leading, spacing: 4) {
                Text("Guest Mode")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text("Progress not saved")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: 0xFFFDEB9D), lineWidth: 2)
        )
    }
}

struct KidsStatsCards: View {
    let userLevel: Int
    let totalStars: Int
    let maxStars: Int

    var body: some View {
        HStack(spacing: 16) {
            FunStatsCard(
                emoji: "🏆",
                title: "Level",
                value: "\(userLevel)",
                backgroundColor: Color(hex: 0xFFFDEB9D)
            )
            FunStatsCard(
                emoji: "⭐️",
                title: "Stars",
                value: "\(totalStars)/\(maxStars)",
                backgroundColor: Color(hex: 0xFFFFA3B1)
            )
        }
    }
}

struct FunStatsCard: View {
    let emoji: String
    let title: String
    let value: String
    let backgroundColor: Color

    var body: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 36))

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))

            Text(value)
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(backgroundColor.opacity(0.35), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.25), lineWidth: 2)
        )
    }
}

struct KidsAchievementsSection: View {
    let totalStars: Int
    let userLevel: Int
    let maxStars: Int

    var body: some View {
        let step = max(1, maxStars / 5)

        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Text("🏅")
                    .font(.system(size: 34))
                Text("Your Achievements")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack {
                ForEach(0..<5) { index in
                    AnimatedAchievementStar(earned: totalStars >= (index + 1) * step, index: index)
                }
            }

            Text("\(totalStars) / \(maxStars) stars earned")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)

            Text("Level \(userLevel) explorer")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
                .frame(maxWidth: .infinity)

            Text("Keep going! You're doing great! 🎉")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
        }
        .padding(24)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(colors: [
                        Color(hex: 0xFF9A9E),
                        Color(hex: 0xFAD0C4)
                    ], startPoint: .leading, endPoint: .trailing),
                    lineWidth: 3
                )
        )
    }
}

struct AnimatedAchievementStar: View {
    let earned: Bool
    let index: Int

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let scale = earned ? 1 + 0.1 * sin(t + Double(index)) : 1
            let rotation = earned ? Angle(degrees: (t * 20).truncatingRemainder(dividingBy: 360)) : .zero

            Image(systemName: earned ? "star.fill" : "star")
                .font(.system(size: 38))
                .foregroundStyle(earned ? Color(hex: 0xFFD700) : .white.opacity(0.3))
                .scaleEffect(scale)
                .rotationEffect(rotation)
                .frame(maxWidth: .infinity)
        }
    }
}

struct KidsAccountInfoCard: View {
    let profile: UserProfile

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Text("👤")
                    .font(.system(size: 32))
                Text("My Info")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
            }

            Divider().background(Color.white.opacity(0.2))

            VStack(spacing: 16) {
                FunInfoRow(emoji: "👤", label: "Name", value: profile.name)
                FunInfoRow(emoji: "📧", label: "Email", value: profile.email ?? "Guest Mode")
                if !profile.provider.isEmpty {
                    FunInfoRow(emoji: "🔐", label: "Login", value: profile.provider.capitalized)
                }
                FunInfoRow(emoji: "🎯", label: "Progress", value: "\(profile.totalStars)/\(profile.maxStars) stars")
            }

            Divider().background(Color.white.opacity(0.2))

            HStack {
                Text(levelEmoji(profile.level))
                    .font(.system(size: 40))
                VStack(alignment: .leading) {
                    Text(levelTitle(profile.level))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Level \(profile.level)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(colors: [
                    Color(hex: 0xA18CD1),
                    Color(hex: 0xFBC2EB)
                ], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 20)
            )
        }
        .padding(24)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
        )
    }

    private func levelTitle(_ level: Int) -> String {
        switch level {
        case 1: return "Beginner"
        case 2...3: return "Learner"
        case 4...5: return "Player"
        case 6...7: return "Skilled"
        case 8...10: return "Expert"
        default: return "Master"
        }
    }

    private func levelEmoji(_ level: Int) -> String {
        switch level {
        case 1: return "🎹"
        case 2...3: return "🎶"
        case 4...5: return "🎵"
        case 6...7: return "⭐️"
        case 8...10: return "🏆"
        default: return "👑"
        }
    }
}

struct FunInfoRow: View {
    let emoji: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.2), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct KidsAvatarsSection: View {
    let avatars: [Avatar]
    let isLoading: Bool
    let activeAvatar: Avatar?
    var onAvatarTap: ((Avatar) -> Void)?
    var onActivateAvatar: ((Avatar) -> Void)?
    var onDeleteAvatar: ((Avatar) -> Void)?
    var onCreateAvatarTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Avatars")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)

                Spacer()

                if let onCreateAvatarTap {
                    Button(action: onCreateAvatarTap) {
                        Label("New Avatar", systemImage: "plus.circle")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.2), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                }
            }

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .padding(.vertical, 32)
            } else if avatars.isEmpty {
                VStack(spacing: 12) {
                    Text("🤖")
                        .font(.system(size: 48))
                    Text("No avatars yet")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Create your first avatar to start the fun!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))

                    if let onCreateAvatarTap {
                        Button(action: onCreateAvatarTap) {
                            Text("Create Avatar")
                                .font(.system(size: 15, weight: .semibold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.25), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(avatars) { avatar in
                            KidsAvatarProfileCard(
                                avatar: avatar,
                                isActive: activeAvatar?.id == avatar.id,
                                onPreview: onAvatarTap == nil ? nil : { onAvatarTap?(avatar) },
                                onActivate: onActivateAvatar == nil ? nil : { onActivateAvatar?(avatar) },
                                onDelete: onDeleteAvatar == nil ? nil : { onDeleteAvatar?(avatar) }
                            )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(colors: [
                        Color(hex: 0x7F7FD5),
                        Color(hex: 0xE786D7)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 3
                )
        )
    }
}

struct KidsAvatarProfileCard: View {
    let avatar: Avatar
    let isActive: Bool
    let onPreview: (() -> Void)?
    let onActivate: (() -> Void)?
    let onDelete: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [
                            Color(hex: 0xFAD0C4).opacity(0.6),
                            Color(hex: 0xFFD1FF).opacity(0.6)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 130, height: 130)
                    .overlay(
                        Circle()
                            .stroke(isActive ? Color.yellow : Color.white.opacity(0.5), lineWidth: isActive ? 5 : 2)
                    )

                avatarImage
            }
            .onTapGesture { onPreview?() }

            Text(avatar.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            if isActive {
                Label("Active", systemImage: "star.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2), in: Capsule())
            }

            HStack(spacing: 10) {
                if let onActivate, !isActive {
                    Button(action: onActivate) {
                        Label("Activate", systemImage: "checkmark.circle")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.25), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                }

                if let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .bold))
                            .padding(8)
                            .background(Color.red.opacity(0.25), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                }
            }
        }
        .frame(width: 170)
        .padding(14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let imageUrl = avatar.avatarImageUrl, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ProgressView()
                        .tint(.white)
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 110, height: 110)
            .clipShape(Circle())
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.white.opacity(0.25))
            .frame(width: 110, height: 110)
            .overlay(
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.6))
            )
    }
}

struct KidsEditNameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draftName: String
    @State private var errorMessage: String? = nil
    let onSave: (String) -> Void

    init(currentName: String, onSave: @escaping (String) -> Void) {
        _draftName = State(initialValue: currentName)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Change Your Name ✏️")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(AppColors.rainbowBlue)
                    .padding(.top, 24)

                Text("Pick an awesome name that shows up across the app.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                TextField("Your Name", text: $draftName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(errorMessage == nil ? Color.clear : Color.red, lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .onChange(of: draftName) { newValue in
                        validate(newValue)
                    }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draftName.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(errorMessage != nil || draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func validate(_ name: String) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Name can't be empty"
        } else if name.count < 2 {
            errorMessage = "Name needs at least 2 letters"
        } else if name.count > 30 {
            errorMessage = "Name is too long"
        } else {
            errorMessage = nil
        }
    }
}
