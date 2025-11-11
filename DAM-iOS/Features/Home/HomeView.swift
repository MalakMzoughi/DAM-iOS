//
//  HomeView.swift
//  DAM-iOS
//
//  Created by iMac on 10/11/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: UserSession
    @EnvironmentObject var router: AppRouter

    @State private var showComingSoon = false
    @State private var showLoginNeeded = false
    @State private var selectedLevel: LevelNode? = nil
    @State private var showProfile = false

    // If you already have LevelNode data coming from backend, use that.
    // For now, reuse your mock but drive unlocks by session.
    private var levels: [LevelNode] { .mock } // keep your existing mock source

    // Progress helpers
    private var highestUnlockedIndex: Int {
        // Unlocked = level number <= current user level (guests => only 1)
        let current = max(1, session.profile.level)
        return (levels.lastIndex { $0.number <= current } ?? 0)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background: sky → ocean with waves
                LinearGradient(
                    colors: [AppColors.skyBlue, AppColors.oceanDeep],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                CloudLayer(height: 90).padding(.top, 8)
                WaveBackground().opacity(0.25).ignoresSafeArea(edges: .bottom)

                VStack(spacing: 12) {
                    // Banner
                    banner
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Map (vertical scroll)
                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack {
                            // 1) reached segment (green)
                            path(upTo: highestUnlockedIndex)
                                .stroke(style: StrokeStyle(lineWidth: 3,
                                                           lineCap: .round,
                                                           dash: [8, 10]))
                                .foregroundStyle(AppColors.rainbowGreen.opacity(0.9))
                                .padding(.top, 60)

                            // 2) remaining segment (gray)
                            path(from: highestUnlockedIndex, to: levels.count - 1)
                                .stroke(style: StrokeStyle(lineWidth: 3,
                                                           lineCap: .round,
                                                           dash: [8, 10]))
                                .foregroundStyle(Color.gray.opacity(0.5))
                                .padding(.top, 60)

                            VStack(spacing: 60) {
                                ForEach(levels) { node in
                                    islandRow(for: node, geo: geo)
                                }
                            }
                            .padding(.vertical, 60)
                        }
                    }
                }

                // Coming soon dialog
                CenterDialog(isPresented: $showComingSoon) {
                    ComingSoonSheet {
                        showComingSoon = false
                        selectedLevel = nil
                    }
                }

                // Login needed (guest trying locked content)
                CenterDialog(isPresented: $showLoginNeeded) {
                    VStack(spacing: 16) {
                        Text("Login Required")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.rainbowBlue)
                        Text("Create an account or login to unlock more levels and save your progress!")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppColors.textLight)
                        Button {
                            router.current = .landing // go back to landing to show login
                        } label: {
                            Text("Go to Login")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GradientButtonStyle(gradient: .loginPurple))
                    }
                    .padding(20)
                    .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
        }
    }

    // MARK: - Components

    private var banner: some View {
        HStack(spacing: 12) {
            // Avatar button → open profile
            Button { showProfile = true } label: {
                ZStack {
                    Circle().fill(AppColors.rainbowPink.opacity(0.25))
                    Image(systemName: "pianokeys.inverse") // iOS 17; fallback to "music.note" if needed
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColors.rainbowBlue)
                }
                .frame(width: 42, height: 42)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(session)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.profile.name.isEmpty ? "Guest Player" : session.profile.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(levelLabel(session.profile.level))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textLight)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "star.fill").foregroundStyle(AppColors.rainbowYellow)
                Text("\(session.profile.totalStars)/\(session.profile.maxStars)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
        }
        .padding(12)
        .background(AppColors.cardBackground.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    private func islandRow(for node: LevelNode, geo: GeometryProxy) -> some View {
        // lane 0 / lane 1 → alternate vertical offset for playful path
        let laneYOffset: CGFloat = node.lane == 0 ? 0 : 40
        let unlocked = node.number <= max(1, session.profile.level)

        return VStack(spacing: 10) {
            ZStack {
                // water hump under island
                WaveHump()
                    .fill(AppColors.seaFoam.opacity(0.8))
                    .frame(height: 60)

                Capsule()
                    .fill(LinearGradient(colors: [AppColors.rainbowGreen, AppColors.seaFoam],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: 260, height: 36)
                    .offset(y: -6)

                // level card tap
                LevelCard(node: node) {
                    selectedLevel = node
                    if unlocked {
                        showComingSoon = true
                    } else {
                        showLoginNeeded = true
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .bold))
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                            .padding(6)
                    }
                }
                .offset(y: -68)
                .allowsHitTesting(true)
            }
        }
        .frame(maxWidth: .infinity)
        .offset(x: node.lane == 0 ? -geo.size.width * 0.12 : geo.size.width * 0.12,
                y: laneYOffset)
    }

    // MARK: - Path building for progress coloring

    // Draw from start to lastIndex inclusive
    private func path(upTo lastIndex: Int) -> Path {
        let count = levels.count
        guard count > 0 else { return Path() }

        // clamp to [-1, count-1]; -1 means “draw nothing”
        let clampedLast = max(-1, min(lastIndex, count - 1))
        guard clampedLast >= 0 else { return Path() } // nothing unlocked yet

        return makePath(range: 0...clampedLast)
    }

    // Draw from startIndex to endIndex inclusive
    
    private func path(from startIndex: Int, to endIndex: Int) -> Path {
        let count = levels.count
        guard count > 0 else { return Path() }

        // clamp to [0, count-1]
        let s = max(0, min(startIndex, count - 1))
        let e = max(0, min(endIndex,   count - 1))
        guard e >= s else { return Path() } // nothing to draw

        return makePath(range: s...e)
    }

    private func makePath(range: ClosedRange<Int>) -> Path {
        var p = Path()
        let count = levels.count
        guard count > 0 else { return p }

        // build X positions (alternating L/R) for every level
        let xs: [CGFloat] = (0..<count).map { i in (i % 2 == 0) ? -120 : 120 }
        let baseY: CGFloat = 120
        let stepY: CGFloat = 180

        // start point (safe)
        let start = max(0, min(range.lowerBound, count - 1))
        p.move(to: CGPoint(x: xs[start], y: baseY + CGFloat(start) * stepY))

        // compute safe loop bounds
        let loopStart = start + 1
        let loopEnd   = min(range.upperBound, count - 1)

        // only loop if we truly have at least one segment to draw
        if loopStart <= loopEnd {
            for i in loopStart...loopEnd {
                let x    = xs[i]
                let prev = baseY + CGFloat(i - 1) * stepY
                let cur  = baseY + CGFloat(i) * stepY
                let c1   = CGPoint(x: x * 0.5, y: prev + 60)
                let c2   = CGPoint(x: x * 0.8, y: cur  - 60)
                p.addCurve(to: CGPoint(x: x, y: cur), control1: c1, control2: c2)
            }
        }

        return p
    }
    // MARK: - Labels

    private func levelLabel(_ level: Int) -> String {
        switch level {
        case 1: return "Beginner"
        case 2...3: return "Learner"
        case 4...5: return "Player"
        case 6...7: return "Skilled"
        case 8...10: return "Expert"
        default: return "Master"
        }
    }
}

// small green hump shape for island waterline
struct WaveHump: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.midY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                   control1: CGPoint(x: rect.width * 0.25, y: rect.minY),
                   control2: CGPoint(x: rect.width * 0.75, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: 0, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppSettings())
            .environmentObject(AppRouter())
            .environmentObject(UserSession())
            .previewLayout(.sizeThatFits)
            .background(Color.white)
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
