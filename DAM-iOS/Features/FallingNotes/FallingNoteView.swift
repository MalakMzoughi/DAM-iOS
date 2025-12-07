//
//  FallingNoteView.swift
//  Falling Notes System
//
//  Created on 2025-12-06.
//

import SwiftUI

/// Visual representation of a single falling note
struct FallingNoteView: View {
    let note: MusicNote
    let width: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(note.color)
                .shadow(color: note.color.opacity(0.6), radius: 8, x: 0, y: 4)
            
            Text(note.displayName)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: width * 0.85, height: 80)
    }
}

#Preview {
    VStack(spacing: 20) {
        FallingNoteView(note: .DO, width: 50)
        FallingNoteView(note: .RE, width: 50)
        FallingNoteView(note: .MI, width: 50)
        FallingNoteView(note: .FA, width: 50)
        FallingNoteView(note: .SOL, width: 50)
        FallingNoteView(note: .LA, width: 50)
        FallingNoteView(note: .SI, width: 50)
    }
    .padding()
    .background(Color.black)
}
