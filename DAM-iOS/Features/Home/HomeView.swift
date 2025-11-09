//
//  HomeView.swift
//  DAM-iOS
//
//  Created by iMac on 10/11/2025.
//

import SwiftUI

struct HomeView: View {
    @State private var showComingSoon = false
    @State private var selectedLevel: LevelNode? = nil

    private let profile = PlayerProfile.mock
    private let levels: [LevelNode] = .mock

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background: sky → ocean with waves
                LinearGradient(colors: [AppColors.skyBlue, AppColors.oceanDeep],
                               startPoint: .top, endPoint: .bottom)
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
                            // Dotted path connecting islands
                            dottedPath
                                .stroke(style: StrokeStyle(lineWidth: 3,
                                                          lineCap: .round,
                                                          dash: [8, 10]))
                                .foregroundStyle(AppColors.rainbowYellow.opacity(0.9))
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

                // Dialog
                CenterDialog(isPresented: $showComingSoon) {
                    ComingSoonSheet {
                        showComingSoon = false
                        selectedLevel = nil
                    }
                }
            }
        }
    }

    // MARK: - Components

    private var banner: some View {
        HStack {
            // Avatar
            ZStack {
                Circle().fill(AppColors.rainbowPink.opacity(0.25))
                Image(systemName: "pianokeys.inverse") // iOS17; fallback below
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColors.rainbowBlue)
            }
            .frame(width: 42, height: 42)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(profile.levelLabel)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textLight)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "star.fill").foregroundStyle(AppColors.rainbowYellow)
                Text("\(profile.starsOwned)/\(profile.starsTotal)")
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

        return VStack(spacing: 10) {
            // island base
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

                // level card
                LevelCard(node: node) {
                    selectedLevel = node
                    showComingSoon = true
                }
                .offset(y: -68)
            }
        }
        .frame(maxWidth: .infinity)
        .offset(x: node.lane == 0 ? -geo.size.width * 0.12 : geo.size.width * 0.12,
                y: laneYOffset)
    }

    // Dotted path connecting centers of rows
    private var dottedPath: Path {
        var p = Path()
        // points along the vertical stack, alternating left/right
        let xs: [CGFloat] = [-120, 120, -120, 120]
        var y: CGFloat = 120
        for i in 0..<xs.count {
            let x = xs[i]
            if i == 0 {
                p.move(to: CGPoint(x: x, y: y))
            } else {
                // slight curve toward next point
                let prevY = y - 180
                let ctrl1 = CGPoint(x: x * 0.5, y: prevY + 60)
                let ctrl2 = CGPoint(x: x * 0.8, y: y - 60)
                p.addCurve(to: CGPoint(x: x, y: y), control1: ctrl1, control2: ctrl2)
            }
            y += 180
        }
        return p
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
            .previewLayout(.sizeThatFits)
            .background(Color.white)
            .previewInterfaceOrientation(.landscapeLeft)
    }
}

