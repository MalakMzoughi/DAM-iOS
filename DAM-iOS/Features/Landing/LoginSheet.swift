//
//  LoginSheet.swift
//  DAM-iOS
//
//  Created by iMac on 9/11/2025.
//

import SwiftUI

struct LoginSheet: View {
    var onApple: () -> Void
    var onGoogle: () -> Void
    var onFacebook: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Login")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Button {
                onApple()
            } label : {
                Label("Continue with Apple", systemImage: "apple.logo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            
            
            Button {
                onGoogle()
            } label : {
                Label("Continue with Google", systemImage: "g.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            
            
            Button {
                onFacebook()
            } label : {
                Label("Continue with Facebook", systemImage: "f.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: 540)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }
}

struct LoginSheet_Previews: PreviewProvider {
    static var previews: some View {
        LoginSheet(onApple: {}, onGoogle: {}, onFacebook: {})
            .previewLayout(.sizeThatFits)
            .background(Color.gray)
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
