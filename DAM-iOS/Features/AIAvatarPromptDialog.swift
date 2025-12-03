//
//  AIAvatarPromptDialog.swift
//  DAM-iOS
//
//  AI Avatar Prompt Dialog for generating avatars with Gemini AI
//

import SwiftUI

// MARK: - Color Extension for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct AIAvatarPromptDialog: View {
    let avatarName: String
    let onGenerateAvatar: (String, String) -> Void
    let onBack: () -> Void
    let onDismiss: () -> Void
    let isLoading: Bool
    let error: String?
    
    @State private var prompt: String = ""
    @State private var selectedStyle: String = "cartoon"
    @State private var showPromptError: Bool = false
    @State private var showExamples: Bool = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isLoading {
                        onDismiss()
                    }
                }
            
            // Dialog content
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Text("🤖 AI Avatar Creator")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: { showExamples.toggle() }) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        
                        Text("Describe your dream avatar for \"\(avatarName)\"")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        
                        // Examples section
                        if showExamples {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("💡 Example Prompts:")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                
                                ForEach(examplePrompts, id: \.self) { example in
                                    Button(action: {
                                        prompt = example
                                        showExamples = false
                                    }) {
                                        Text("• \(example)")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.9))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(8)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(16)
                            .transition(.opacity)
                        }
                        
                        // Prompt input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Describe your avatar")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextEditor(text: $prompt)
                                .frame(height: 120)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(showPromptError ? Color.red : Color.clear, lineWidth: 2)
                                )
                                .disabled(isLoading)
                                .onChange(of: prompt) { _ in
                                    showPromptError = false
                                }
                            
                            if prompt.isEmpty {
                                Text("e.g., Naruto with orange clothes")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.leading, 12)
                                    .offset(y: -108)
                                    .allowsHitTesting(false)
                            }
                        }
                        
                        if showPromptError {
                            Text("Please describe your avatar")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                        }
                        
                        // Error message
                        if let error = error {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.white)
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        // Loading indicator
                        if isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                Text("🎨 Creating your avatar with AI magic...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("This may take a few seconds")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: onBack) {
                                Text("← Back")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                            }
                            .disabled(isLoading)
                            
                            Button(action: {
                                if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    showPromptError = true
                                } else {
                                    onGenerateAvatar(prompt, selectedStyle)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                    Text("Generate")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(Color(hex: "667EEA"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading)
                        }
                        
                        // Info text
                        Text("✨ AI will create a unique, kid-friendly avatar based on your description")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(24)
                }
            }
            .frame(maxWidth: 500)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "667EEA"),
                        Color(hex: "764BA2")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(20)
        }
    }
    
    private var examplePrompts: [String] {
        [
            "Naruto with orange clothes",
            "Mickey Mouse style character",
            "Pikachu inspired character",
            "Superhero with blue cape",
            "Princess with pink hair",
            "Ninja with black outfit",
            "Wizard with purple robe"
        ]
    }
}

#Preview {
    AIAvatarPromptDialog(
        avatarName: "SuperKid",
        onGenerateAvatar: { _, _ in },
        onBack: {},
        onDismiss: {},
        isLoading: false,
        error: nil
    )
}
