//
//  UIHelpers.swift
//  DAM-iOS
//
//  Created by iMac on 9/11/2025.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22,weight: .bold,design: .rounded))
            .padding(.horizontal, 28).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppColors.rainbowBlue.opacity(configuration.isPressed ? 0.85 : 1.0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25),lineWidth: 1)
            )
            .foregroundColor(.black)
            .shadow(radius: configuration.isPressed ? 2 : 8, y: configuration.isPressed ? 1 : 4)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

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

// Re-usable centered dialog (keeps content compact; not full height)
struct CenterDialog<Content: View>: View {
    @Binding var isPresented: Bool
    var content: () -> Content
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }
                content()
                    .background(.ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .padding(32)
            }
            .transition(.opacity)
            .animation(.easeOut(duration: 0.2), value: isPresented)
        }
    }
}
