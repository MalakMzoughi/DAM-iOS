//
//  ConfettiExplosion.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 23/11/2025.
//

import SwiftUI

struct ConfettiExplosionView: View {
    private let colors: [Color] = [
        .pink, .blue, .yellow, .green, .orange, .purple
    ]

    @State private var particles: [ConfettiParticle] = []
    @State private var time: CGFloat = 0

    var body: some View {
        Canvas { ctx, size in
            for p in particles {
                var transform = ctx.transform

                // Apply translation
                transform = transform.translatedBy(
                    x: p.x * size.width,
                    y: (p.y + time * p.speed).truncatingRemainder(dividingBy: size.height)
                )
                ctx.transform = transform

                // Draw particle
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: -p.radius,
                        y: -p.radius,
                        width: p.radius * 2,
                        height: p.radius * 2)
                    ),
                    with: .color(p.color)
                )
            }
        }
        .ignoresSafeArea()
        .task {
            generateParticles()
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 16_000_000) // ~60 FPS
                } catch {
                    break
                }
                await MainActor.run {
                    time += 0.01
                }
            }
        }
    }

    private func generateParticles() {
        particles = (0..<60).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                radius: CGFloat.random(in: 5...12),
                color: colors.randomElement() ?? .white,
                speed: CGFloat.random(in: 0.5...1.5)
            )
        }
    }

    struct ConfettiParticle {
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let color: Color
        let speed: CGFloat
    }
}

