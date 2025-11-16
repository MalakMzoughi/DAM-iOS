//
//  ColorHex.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI

extension Color {
    /// Hex in RRGGBB (e.g. 0x64B5F6)
    init(hex rgb: UInt32) {
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8)  & 0xFF) / 255.0
        let b = Double(rgb         & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }

    /// Hex in AARRGGBB (e.g. 0xD5F0628A from Android with alpha)
    init(argb: UInt32) {
        let a = Double((argb >> 24) & 0xFF) / 255.0
        let r = Double((argb >> 16) & 0xFF) / 255.0
        let g = Double((argb >> 8)  & 0xFF) / 255.0
        let b = Double(argb         & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b, opacity: a)
    }
}
