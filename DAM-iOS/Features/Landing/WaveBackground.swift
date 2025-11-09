//
//  WaveBackground.swift
//  DAM-iOS
//
//  Created by iMac on 9/11/2025.
//

import SwiftUI

struct WaveBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/60.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate

            // Break out phase math (helps the type-checker)
            let p1 = Self.phase(t, speed: 1.0)
            let p2 = Self.phase(t, speed: 0.8)

            ZStack {
                LinearGradient(colors: [AppColors.skyBlue, AppColors.oceanDeep],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                wave(amplitude: 22, wavelength: 120, phase: p1, color: AppColors.seaFoam.opacity(0.35), y: 40)
                wave(amplitude: 16, wavelength:  80, phase: p2, color: AppColors.oceanLight.opacity(0.25), y: 55)
            }
        }
    }

    private static func phase(_ t: TimeInterval, speed: Double) -> CGFloat {
        let twoPi = Double.pi * 2
        let raw = fmod(t * speed, twoPi)
        return CGFloat(raw)
    }

    @ViewBuilder
    private func wave(amplitude: CGFloat, wavelength: CGFloat, phase: CGFloat, color: Color, y: CGFloat) -> some View {
        WaveShape(amplitude: amplitude, wavelength: wavelength, phase: phase)
            .fill(color)
            .blur(radius: 1)
            .offset(y: y)
    }
}

struct WaveShape: Shape {
    var amplitude: CGFloat
    var wavelength: CGFloat
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midY = rect.midY + rect.height * 0.2
        p.move(to: CGPoint(x: 0, y: midY))

        var x: CGFloat = 0
        let endX = rect.width
        while x <= endX {
            let rel = x / wavelength
            let y = midY + sin(rel + phase) * amplitude
            p.addLine(to: CGPoint(x: x, y: y))
            x += 1
        }

        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
