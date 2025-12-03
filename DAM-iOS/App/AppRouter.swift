//
//  AppRouter.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI

enum AppScreen {
    case landing
    case home
    case profile
    case level(Level)
}

final class AppRouter: ObservableObject {
    @Published var current: AppScreen = .landing
    
    func navigate(to screen: AppScreen) {
        withAnimation {
            current = screen
        }
    }
}
