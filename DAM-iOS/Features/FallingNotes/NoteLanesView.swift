//
//  NoteLanesView.swift
//  Falling Notes System
//
//  Created on 2025-12-06.
//

import SwiftUI

/// The main view that displays all 7 vertical lanes with falling notes
struct NoteLanesView: View {
    @Binding var fallingNotes: [FallingNote]
    let screenHeight: CGFloat
    let keyboardHeight: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let laneWidth = geometry.size.width / 7
            
            ZStack(alignment: .top) {
                // Background lanes (optional visual guides)
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { lane in
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: laneWidth)
                            .border(Color.white.opacity(0.1), width: 0.5)
                    }
                }
                
                // Falling notes
                ForEach(fallingNotes) { fallingNote in
                    FallingNoteView(note: fallingNote.note, width: laneWidth)
                        .position(
                            x: laneWidth * CGFloat(fallingNote.lane) + laneWidth / 2,
                            y: fallingNote.yPosition
                        )
                }
            }
        }
    }
}

struct NoteLanesView_Previews: PreviewProvider {
    static var previews: some View {
        NoteLanesPreviewWrapper()
    }
}

private struct NoteLanesPreviewWrapper: View {
    @State private var notes: [FallingNote] = [
        FallingNote(note: .DO, lane: 0, targetTime: 1.0),
        FallingNote(note: .RE, lane: 1, targetTime: 1.5),
        FallingNote(note: .MI, lane: 2, targetTime: 2.0),
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            NoteLanesView(
                fallingNotes: $notes,
                screenHeight: 800,
                keyboardHeight: 100
            )
        }
    }
}
