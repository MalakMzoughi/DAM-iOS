//
//  LevelCard.swift
//  DAM-iOS
//
//  Created by iMac on 10/11/2025.
//

import SwiftUI

struct LevelCard: View {
    let node: LevelNode
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Header strip with ship icon
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(AppColors.cardBackground)
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 6)

                    VStack(spacing: 10) {
                        ZStack {
                            LinearGradient(colors: [AppColors.oceanDeep, AppColors.rainbowBlue],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                                .frame(height: 56)
                                .clipShape(RoundedCorners(radius: 22, corners: [.topLeft, .topRight]))

                            Circle()
                                .fill(AppColors.cardBackground)
                                .frame(width: 54, height: 54)
                                .offset(y: 28)
                                .overlay(
                                    Image(systemName: "sailboat.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(AppColors.rainbowBlue)
                                        .offset(y: 28)
                                )
                        }

                        Text("Level \(node.index)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColors.rainbowBlue)

                        Text(node.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.textDark)

                        Text(node.subtitle)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(AppColors.textLight)

                        HStack(spacing: 4) {
                            ForEach(0..<3) { i in
                                Image(systemName: i < node.stars ? "star.fill" : "star")
                                    .foregroundStyle(AppColors.rainbowYellow)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                    .padding(.top, 0)
                }
            }
            .frame(width: 220, height: 250)
        }
        .buttonStyle(.plain)
    }
}

// Rounded corners helper for header
struct RoundedCorners: Shape {
    var radius: CGFloat = 16
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

