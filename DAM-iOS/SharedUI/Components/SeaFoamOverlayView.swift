//
//  SeaFoamOverlayView.swift
//  DAM-iOS
//
//  Created by Malak on 14/11/2025.
//

import SwiftUI

struct SeaFoamOverlayView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            ZStack {
                foamBand(width: width, height: 80)
                    .offset(x: animate ? 40 : -40, y: -120)

                foamBand(width: width * 0.9, height: 60)
                    .offset(x: animate ? -30 : 30, y: 40)

                foamBand(width: width * 0.8, height: 70)
                    .offset(x: animate ? 50 : -50, y: 160)
            }
            .blendMode(.screen)          // makes it feel like light on water
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 5)
                        .repeatForever(autoreverses: true)
                ) {
                    animate = true
                }
            }
        }
        .allowsHitTesting(false)        // don’t block taps
    }

    private func foamBand(width: CGFloat, height: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(0.0),
                        .white.opacity(0.4),
                        .white.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .blur(radius: 15)
            .opacity(0.5)
    }
}
