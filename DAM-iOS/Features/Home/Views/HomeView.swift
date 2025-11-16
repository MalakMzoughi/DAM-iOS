//
//  HomeView.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI

struct HomeRootView: View {

    @EnvironmentObject private var userSession: UserSession
    @EnvironmentObject private var router: AppRouter

    @StateObject private var viewModel = HomeMapViewModel()
    @State private var showAddAvatar = false

    var body: some View {
        let isLoggedIn: Bool = {
            switch userSession.state {
            case .loggedIn: return true
            case .guest:    return false
            }
        }()

        ZStack(alignment: .top) {
            SeaMapView(viewModel: viewModel)
                .ignoresSafeArea(edges: .bottom)
                .padding(.top, 90)

            HomeHeaderView(
                profile: userSession.profile,
                isLoggedIn: isLoggedIn,
                totalStars: viewModel.totalStars,
                onBackTap: {
                    router.current = .landing
                },
                onProfileTap: {
                    // Navigate to profile view
                    router.current = .profile
                },
                onAddAvatarTap: {
                    showAddAvatar = true
                }
            )
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showAddAvatar) {
            AvatarNameInputView()
                .environmentObject(userSession)
        }
    }
}


struct HomeRootView_Previews: PreviewProvider {
    static var previews: some View {
        HomeRootView()
            .previewDevice("iPad (9th generation)")
            .previewLayout(.device)
            .background(Color.white)
            .previewInterfaceOrientation(.landscapeRight)
    }
}
