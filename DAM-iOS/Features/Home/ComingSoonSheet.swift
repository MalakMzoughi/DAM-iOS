//
//  ComingSoonSheet.swift
//  DAM-iOS
//
//  Created by iMac on 10/11/2025.
//

import SwiftUI

struct ComingSoonSheet: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [AppColors.rainbowIndigo, AppColors.rainbowViolet],
                                                startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("Coming Soon!")
                .font(.system(size: 26, weight: .heavy, design: .rounded))

            Text("This level is under construction!")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textDark)

            Text("We're working hard to bring you an amazing piano learning experience! 🎹")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(AppColors.textDark)
                .multilineTextAlignment(.center)

            Button("Got it!") { onDismiss() }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.horizontal, 28).padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [AppColors.rainbowBlue, AppColors.oceanLight],
                                             startPoint: .leading, endPoint: .trailing))
                )
                .foregroundColor(.white)
        }
        .padding(24)
        .frame(maxWidth: 420)
    }
}
