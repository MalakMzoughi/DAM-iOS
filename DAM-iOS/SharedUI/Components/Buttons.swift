//
//  Buttons.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20,weight: .semibold, design: .rounded))
            .padding(.horizontal, 24).padding(.vertical, 12)
            .background(.ultraThinMaterial, in:RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25),lineWidth: 1)
            )
            .foregroundColor(.white)
    }
}

struct GradientButtonStyle: ButtonStyle {
 let gradient: LinearGradient
  func makeBody(configuration: Configuration) -> some View {
      configuration.label
          .font(.system(size: 22, weight: .bold, design: .rounded))
          .padding(.horizontal, 28).padding(.vertical, 14)
          .background(
              RoundedRectangle(cornerRadius: 18, style: .continuous)
                  .fill(gradient)
                    .opacity(configuration.isPressed ? 0.9 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )
            .foregroundColor(.white)
            .shadow(radius: configuration.isPressed ? 2 : 8, y: configuration.isPressed ? 1 : 4)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension LinearGradient {
    static var guestYellow: LinearGradient {
  LinearGradient(colors: [AppColors.rainbowYellow, AppColors.rainbowOrange],
                       startPoint: .leading, endPoint: .trailing)
    }
    static var loginPurple: LinearGradient {
        LinearGradient(colors: [AppColors.rainbowIndigo, AppColors.rainbowViolet],
                       startPoint: .leading, endPoint: .trailing)
    }
}
