//
//  DAM_iOSApp.swift
//  DAM-iOS
//
//  Created by iMac on 9/11/2025.
//

import SwiftUI

@main
struct DAM_iOSApp: App {
    @StateObject private var settings = AppSettings()
        @StateObject private var router = AppRouter()

        var body: some Scene {
            WindowGroup {
                Group {
                    switch router.current {
                    case .landing:
                        LandingView()
                            .environmentObject(settings)
                            .environmentObject(router)
                    case .home:
                        HomeView()
                            .environmentObject(settings)
                            .environmentObject(router)
                    }
                }
                .preferredColorScheme(.light)
            }
        }
}
