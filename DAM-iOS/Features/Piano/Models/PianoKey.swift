//
//  PianoKey.swift
//  DAM-iOS
//
//  Created by Apple Esprit on 13/11/2025.
//

import Foundation
import SwiftUI

// Type de touche (blanche ou noire)
enum NoteType {
    case white
    case black
}

// Modèle représentant une touche de piano
struct PianoKey: Identifiable {
    let id: UUID = UUID()
    let note: String        // "Do", "Ré", "Mi", etc.
    let octave: Int         // 4 par défaut
    let type: NoteType      // white ou black
    let frequency: Double   // Fréquence en Hz pour le son
    let color: Color        // Couleur visuelle de la touche
}

