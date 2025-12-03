//
//  LevelFlowCoordinator.swift
//  DAM-iOS
//
//  Manages the complete flow: Intro → Selection → Game → Completion → Home
//

import SwiftUI

struct LevelFlowCoordinator: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var router: AppRouter
    
    let level: Level
    
    @State private var currentStep: FlowStep = .intro
    @State private var shouldDismiss = false
    @State private var selectedPianoMode: PianoMode?
    @State private var selectedSublevel: Sublevel?
    @State private var showSublevelSheet = false
    
    enum FlowStep {
        case intro
        case game
    }
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .intro:
                LevelIntroDialogView(
                    level: level,
                    onChooseSublevel: {
                        showSublevelSheet = true
                    }
                )
                
            case .game:
                if let sublevel = selectedSublevel, let mode = selectedPianoMode {
                    LevelScreen(level: level, sublevel: sublevel, pianoMode: mode)
                        .environmentObject(userSession)
                } else {
                    // Should never happen, but gracefully fall back to intro
                    Color.clear
                        .onAppear {
                            currentStep = .intro
                        }
                }
            }
        }
        .sheet(isPresented: $showSublevelSheet) {
            SublevelListView(
                level: level,
                levelId: level.id,
                userId: userSession.isLoggedIn ? userSession.profile.id : nil,
                preselectedMode: selectedPianoMode
            ) { sublevel, mode in
                selectedPianoMode = mode
                selectedSublevel = sublevel
                showSublevelSheet = false
                withAnimation {
                    currentStep = .game
                }
            }
        }
    }
}
