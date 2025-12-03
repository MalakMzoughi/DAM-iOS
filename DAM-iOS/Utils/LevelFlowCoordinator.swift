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
    @State private var selectedPianoMode: PianoMode = .appPiano
    
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
                    onFinished: { mode in
                        selectedPianoMode = mode
                        withAnimation {
                            currentStep = .game
                        }
                    }
                )
                
            case .game:
                LevelScreenWrapper(level: level, pianoMode: selectedPianoMode) {
                    // When game ends (completion dialog dismissed), go back to home
                    router.current = .home
                }
                .environmentObject(userSession)
            }
        }
    }
}

// Wrapper to handle the completion callback from LevelScreen
private struct LevelScreenWrapper: View {
    @EnvironmentObject var userSession: UserSession
    
    let level: Level
    let pianoMode: PianoMode
    let onGameComplete: () -> Void
    
    @State private var showSuccessDialog = false
    @State private var earnedStars = 0
    
    var body: some View {
        LevelScreen(level: level, pianoMode: pianoMode)
            .environmentObject(userSession)
            .onChange(of: showSuccessDialog) { isShowing in
                // This will be triggered by LevelScreen's completion
                // For now, we'll handle this through LevelScreen's own success dialog
            }
    }
}
