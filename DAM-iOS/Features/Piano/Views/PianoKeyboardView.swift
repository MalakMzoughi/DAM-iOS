//
//  PianoKeyboardView.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 13/11/2025
//

import SwiftUI

struct PianoKeyboardView: View {
    let keys: [PianoKey]
    let onKeyPressed: (PianoKey) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(keys) { key in
                PianoKeyView(key: key) {
                    onKeyPressed(key)
                }
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        )
    }
}

// Preview
struct PianoKeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        let testKeys = [
            PianoKey(note: "Do", octave: 4, type: .white, frequency: 261.63, color: Color.red),
            PianoKey(note: "Re", octave: 4, type: .white, frequency: 293.66, color: Color.orange),
            PianoKey(note: "Mi", octave: 4, type: .white, frequency: 329.63, color: Color.yellow),
            PianoKey(note: "Fa", octave: 4, type: .white, frequency: 349.23, color: Color.green),
            PianoKey(note: "Sol", octave: 4, type: .white, frequency: 392.00, color: Color.cyan),
            PianoKey(note: "La", octave: 4, type: .white, frequency: 440.00, color: Color.blue),
            PianoKey(note: "Si", octave: 4, type: .white, frequency: 493.88, color: Color.purple)
        ]
        
        return PianoKeyboardView(keys: testKeys) { key in
            print("🎹 Pressed: \(key.note)")
        }
        .padding()
        .background(Color.blue.opacity(0.3))
        .previewInterfaceOrientation(.landscapeLeft)
    }
}

