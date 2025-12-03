//
//  LevelCompletionDialog.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 23/11/2025.
//

import SwiftUI

struct LevelCompletedDialogView: View {
    let stars: Int
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            ConfettiExplosionView()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Level Complete!")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.white)

                Text("Amazing job! 🎉")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                // STARS
                HStack(spacing: 12) {
                    ForEach(0..<3) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 38))
                            .foregroundColor(i < stars ? Color.yellow : Color.gray.opacity(0.4))
                    }
                }

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 40)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.top, 10)
            }
            .padding()
            .background(Color.white.opacity(0.15))
            .cornerRadius(24)
            .shadow(radius: 20)
        }
    }
}
