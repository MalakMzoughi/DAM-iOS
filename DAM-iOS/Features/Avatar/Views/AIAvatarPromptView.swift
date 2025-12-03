//
//  AIAvatarPromptView.swift
//  DAM-iOS
//
//  AI Avatar prompt dialog for Gemini generation
//

import SwiftUI

struct AIAvatarPromptView: View {
    let avatarName: String
    let onGenerate: (String, String) -> Void
    let onDismiss: () -> Void
    let isLoading: Bool
    let error: String?
    
    @State private var prompt: String = ""
    @State private var showPromptError = false
    @State private var showExamples = false
    
    private let examples = [
        "Naruto with orange clothes",
        "Mickey Mouse style character",
        "Pikachu inspired character",
        "Superhero with blue cape",
        "Princess with pink hair",
        "Ninja with black outfit",
        "Wizard with purple robe"
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
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
                            
                            ForEach(examples, id: \.self) { example in
                                Text("• \(example)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        prompt = example
                                        showExamples = false
                                    }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(16)
                        .transition(.opacity)
                    }
                    
                    // Prompt input
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $prompt)
                            .frame(height: 120)
                            .padding(12)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(showPromptError ? Color.red : Color.clear, lineWidth: 2)
                            )
                            .disabled(isLoading)
                        
                        if prompt.isEmpty {
                            Text("e.g., Naruto with orange clothes")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        if showPromptError {
                            Text("Please describe your avatar")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                        }
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
                        .background(Color.red.opacity(0.3))
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
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: onDismiss) {
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
                                showPromptError = false
                                onGenerate(prompt, "cartoon")
                            }
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16))
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
    }
}

// Color extension for hex colors
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
            (a, r, g, b) = (255, 0, 0, 0)
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
