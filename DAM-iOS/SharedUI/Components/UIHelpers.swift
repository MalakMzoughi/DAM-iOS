//
//  UIHelpers.swift
//  DAM-iOS
//
//  Created by Malak on 14/11/2025.
//

import SwiftUI

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

