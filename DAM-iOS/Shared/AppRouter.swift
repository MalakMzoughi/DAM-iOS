//
//  AppRouter.swift
//  DAM-iOS
//
//  Created by iMac on 10/11/2025.
//

import SwiftUI

enum AppScreen {
    case landing
    case home
}

final class AppRouter: ObservableObject {
    @Published var current: AppScreen = .landing
}
