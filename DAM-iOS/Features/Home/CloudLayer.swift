//
//  CloudLayer.swift
//  DAM-iOS
//
//  Created by iMac on 10/11/2025.
//

import SwiftUI

struct CloudLayer: View {
    let height: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let x1 = CGFloat(truncating: NSNumber(value: fmod(t*12, 1600))) - 200
            let x2 = CGFloat(truncating: NSNumber(value: fmod(t*8, 1600))) - 400

            ZStack {
                cloud.opacity(0.6).offset(x: x1, y: 0)
                cloud.opacity(0.5).scaleEffect(0.8).offset(x: x2, y: 40)
                cloud.opacity(0.45).scaleEffect(0.6).offset(x: x1-300, y: 20)
            }
            .frame(height: height)
        }
    }

    private var cloud: some View {
        Capsule()
            .fill(AppColors.cardBackground.opacity(0.85))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
            .frame(width: 160, height: 48)
            .overlay(
                HStack(spacing: -14) {
                    Circle().fill(AppColors.cardBackground).frame(width: 48, height: 48)
                    Circle().fill(AppColors.cardBackground).frame(width: 36, height: 36).offset(y: 6)
                    Circle().fill(AppColors.cardBackground).frame(width: 42, height: 42).offset(y: -4)
                }
            )
            .blur(radius: 0.2)
    }
}

struct CloudLayer_Previews: PreviewProvider {
    static var previews: some View {
        CloudLayer(height: 90)
            .frame(height: 300)
            .previewLayout(.sizeThatFits)
            .background(Color.white)
.previewInterfaceOrientation(.landscapeLeft)
    }
}
