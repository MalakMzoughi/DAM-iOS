//
//  LoginSheet.swift
//  DAM-iOS
//
//  Created by iMac on 9/11/2025.
//

import SwiftUI

struct LoginSheet: View {
    @EnvironmentObject var session: UserSession
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Login").font(.title.bold())

            Button {
                Task {
                    await MainActor.run { isLoading = true; errorText = nil }
                    defer { Task { await MainActor.run { isLoading = false } } }

                    do {
                        try await session.loginWithGoogle()
                        await MainActor.run {
                            router.current = .home
                            dismiss()
                        }
                    } catch {
                        await MainActor.run { errorText = error.localizedDescription }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "g.circle.fill")
                    Text("Continue with Google").bold()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .disabled(isLoading)

            if let errorText {
                Text(errorText).foregroundStyle(.red).font(.footnote)
            }
        }
        .padding(24)
        .frame(maxWidth: 420)
    }
}

struct LoginSheet_Previews: PreviewProvider {
    static var previews: some View {
        LoginSheet()
            .previewLayout(.sizeThatFits)
            .background(Color.gray)
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
