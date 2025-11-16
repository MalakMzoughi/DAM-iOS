//
//  DAM_iOSApp.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI
import GoogleSignIn

@main
struct DAM_iOSApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var router   = AppRouter()
    @StateObject private var session  = UserSession()
    
    

    init() {
        //  Force the SDK to use your **iOS** OAuth client ID (not Web).
        GoogleConfig.ensureConfigured()
        // (Optional) One-time sanity prints – helps diagnose 400 errors.
        GoogleConfig.debugPrint()
    }

    var body: some Scene {
        WindowGroup {
            RootRouterView()
                .environmentObject(settings)
                .environmentObject(router)
                .environmentObject(session)
                .preferredColorScheme(.light)
        }
    }
}

/// Small wrapper so we don’t repeat environment objects on each screen
private struct RootRouterView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        Group {
            switch router.current {
            case .landing: AuthRootView()
            case .home:    HomeRootView()
            case .profile: ProfileView()
            }
        }
    }
}

/// Centralized Google configuration
enum GoogleConfig {
    // ⬇️ REPLACE with the **iOS** OAuth client ID you created in Google Cloud
    private static let iosClientID = "99264359525-6i3m3epo6dnga0gibr94nf22qoq54fi0.apps.googleusercontent.com"

    static func ensureConfigured() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: iosClientID)
    }

    /// Optional: prints what the app is actually using at runtime
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
