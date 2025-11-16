//
//  PianoKeyView.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 13/11/2025
//

import SwiftUI

struct PianoKeyView: View {
    let key: PianoKey
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            // La touche du piano
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            key.color,
                            key.color.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 85, height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 4)
                )
                .shadow(color: .black.opacity(0.4), radius: isPressed ? 5 : 10, x: 0, y: isPressed ? 3 : 8)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
            
            // Label de la note (Do, Ré, Mi...)
            Text(key.note)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.8))
                )
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .onTapGesture {
            // Animation de pression
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            // Jouer le son
            action()
            
            // Retour à l'état normal après 150ms
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}

// Preview
struct PianoKeyView_Previews: PreviewProvider {
    static var previews: some View {
        PianoKeyView(
            key: PianoKey(
                note: "Do",
                octave: 4,
                type: .white,
                frequency: 261.63,
                color: Color.red
            ),
            action: {
                print("Do pressed!")
            }
        )
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}

