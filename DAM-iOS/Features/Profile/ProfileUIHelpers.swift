//
//  ProfileUIHelpers.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 10/11/2025.
//

import SwiftUI

struct FloatingStarsBackground: View {
    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let a = 0.5 + 0.5 * sin(t/1.8)
            let b = 0.5 + 0.5 * sin(t/2.4 + 1.1)
            Canvas { g, size in
                g.fill(Path(ellipseIn: CGRect(x: size.width*0.2, y: size.height*0.1, width: 8, height: 8)),
                       with: .color(.white.opacity(a)))
                g.fill(Path(ellipseIn: CGRect(x: size.width*0.8, y: size.height*0.15, width: 6, height: 6)),
                       with: .color(.white.opacity(b)))
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
            if let p = profile.provider {
                infoRow(icon: "lock", label: "Login Method", value: p.capitalized)
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
