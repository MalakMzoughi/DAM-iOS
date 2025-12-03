//
//  DAM_iOSApp.swift
//  DAM-iOS
//
//  Updated with LevelFlowCoordinator
//

import SwiftUI
import GoogleSignIn

@main
struct DAM_iOSApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var router   = AppRouter()
    @StateObject private var session  = UserSession()

    init() {
        // Force the SDK to use your iOS OAuth client ID
        GoogleConfig.ensureConfigured()
        GoogleConfig.debugPrint()
    }

    var body: some Scene {
        WindowGroup {
            RootRouterView()
                .environmentObject(settings)
                .environmentObject(router)
                .environmentObject(session)
                .preferredColorScheme(.light)
                .statusBar(hidden: true)  // Hide status bar
                .task {
                    // Restore session on app launch
                    await session.restoreSession()
                }
        }
    }
}

/// Root router view that switches screens based on AppRouter.current
private struct RootRouterView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var session: UserSession

    var body: some View {
        ZStack {
            switch router.current {
            case .landing:
                AuthRootView()

            case .profile:
                ProfileView()

            case .home:
                HomeView()

            case .level(let level):
                // 🎮 NEW: Use LevelFlowCoordinator for complete flow
                LevelFlowCoordinator(level: level)
                    .environmentObject(session)
                    .environmentObject(router)
            }
        }
    }
}

/// Centralized Google configuration
enum GoogleConfig {
    private static let iosClientID = "99264359525-6i3m3epo6dnga0gibr94nf22qoq54fi0.apps.googleusercontent.com"

    static func ensureConfigured() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: iosClientID)
    }

    static func debugPrint() {
        let plistClient = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String ?? "<none>"
        let configured  = GIDSignIn.sharedInstance.configuration?.clientID ?? "<nil>"
        let urlTypes    = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") ?? "<none>"

        print("🔎 BundleID:", Bundle.main.bundleIdentifier ?? "<nil>")
        print("🔎 Info.plist GIDClientID:", plistClient)
        print("🔎 Configured clientID:", configured)
        print("🔎 URL Types:", urlTypes)

        let expectedScheme = "com.googleusercontent.apps." +
            iosClientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
        print("🔎 Expected URL scheme:", expectedScheme)
    }
}
