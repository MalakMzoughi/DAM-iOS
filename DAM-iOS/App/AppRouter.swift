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
}

final class AppRouter: ObservableObject {
    @Published var current: AppScreen = .landing
}
