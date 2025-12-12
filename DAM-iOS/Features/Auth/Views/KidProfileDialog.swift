import SwiftUI

struct KidProfileDialog: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var isPresented: Bool

    var body: some View {
        KidFlowGlassCard(viewModel: viewModel) {
            isPresented = false
            viewModel.dismissKidFlow()
        }
    }
}

struct KidOnboardingPanel: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        KidFlowGlassCard(viewModel: viewModel, maxWidth: 520)
            .shadow(color: .black.opacity(0.25), radius: 24, y: 14)
    }
}

private struct KidFlowGlassCard: View {
    @ObservedObject var viewModel: AuthViewModel
    var maxWidth: CGFloat = 580
    var onDismiss: (() -> Void)? = nil

    private var state: KidFlowState { viewModel.kidFlowState }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                KidStepIndicatorView(currentStep: state.step)

                Group {
                    switch state.step {
                    case .accountChoice:
                        KidAccountChoiceView(
                            onExisting: viewModel.showReturningKidLogin,
                            onNew: viewModel.showUniqueNameStep
                        )
                    case .returningLogin:
                        KidReturningLoginView(
                            uniqueName: state.returningUniqueName,
                            errorMessage: state.returningError,
                            isLoading: state.isSavingProfile,
                            onChange: viewModel.updateReturningUniqueName,
                            onSubmit: viewModel.loginExistingKid,
                            onBack: viewModel.goBackToAccountChoice
                        )
                    case .uniqueName:
                        KidUniqueNameView(
                            uniqueName: state.uniqueName,
                            errorMessage: state.uniqueNameError,
                            onChange: viewModel.updateUniqueName,
                            onSubmit: viewModel.proceedFromUniqueName,
                            onBack: viewModel.goBackToAccountChoice,
                            onGoogle: handleGoogleTap
                        )
                    case .profileDetails:
                        KidProfileDetailsView(
                            state: state,
                            onAvatarSelect: viewModel.selectAvatarOption,
                            onNameChange: viewModel.updateKidName,
                            onAgeChange: viewModel.updateKidAge,
                            onSave: viewModel.saveKidProfileTapped,
                            onBack: viewModel.showUniqueNameStep
                        )
                    case .greeting:
                        KidGreetingView(
                            profile: state.activeProfile,
                            onContinue: viewModel.handleKidGreetingContinue,
                            onSwitchProfile: viewModel.changeKidProfile
                        )
                    }
                }

                if state.isSavingProfile {
                    ProgressView("Working magic…")
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.rainbowYellow))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(28)
        }
        .kidScrollTweaks()
        .frame(maxWidth: maxWidth)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            AppColors.rainbowYellow,
                            AppColors.rainbowOrange,
                            AppColors.rainbowPink,
                            AppColors.rainbowBlue,
                            AppColors.rainbowGreen
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dialogTitle)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(dialogSubtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            Spacer()
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .padding(10)
                        .background(Color.white.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func handleGoogleTap() {
        onDismiss?()
        viewModel.signInWithGoogleTapped()
    }

    private var dialogTitle: String {
        switch state.step {
        case .accountChoice: return "Choose Your Path"
        case .returningLogin: return "Already a Hero?"
        case .uniqueName: return "Create a Magic Name"
        case .profileDetails: return "Personalize the Journey"
        case .greeting: return "Ready to Play"
        }
    }

    private var dialogSubtitle: String {
        switch state.step {
        case .accountChoice: return "Add a brand-new player or return to an existing adventure."
        case .returningLogin: return "Type the unique name you used before."
        case .uniqueName: return "Letters, numbers, and _ are allowed."
        case .profileDetails: return "Pick an avatar and tell us who is playing."
        case .greeting: return "Everything is set—let's dive back in!"
        }
    }
}

private extension View {
    @ViewBuilder
    func kidScrollTweaks() -> some View {
        if #available(iOS 16.0, *) {
            self
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
        } else {
            self
        }
    }
}

// MARK: - Subviews

private struct KidAccountChoiceView: View {
    let onExisting: () -> Void
    let onNew: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Do you already have a magic account?")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Button("Yes, load my adventure") { onExisting() }
                .buttonStyle(GradientButtonStyle(gradient: .loginPurple))
            Button("No, create a new player") { onNew() }
                .buttonStyle(GradientButtonStyle(gradient: .guestYellow))
        }
    }
}

private struct KidReturningLoginView: View {
    let uniqueName: String
    let errorMessage: String?
    let isLoading: Bool
    let onChange: (String) -> Void
    let onSubmit: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter your magic name")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            TextField("Magic name", text: binding)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
            }
            Button(action: onSubmit) {
                Text(isLoading ? "Loading…" : "Enter the island")
                    .frame(maxWidth: .infinity)
            }
            .disabled(isLoading || uniqueName.isEmpty)
            .buttonStyle(GradientButtonStyle(gradient: .loginPurple))

            Button("← Back") { onBack() }
                .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var binding: Binding<String> {
        Binding(
            get: { uniqueName },
            set: onChange
        )
    }
}

private struct KidUniqueNameView: View {
    let uniqueName: String
    let errorMessage: String?
    let onChange: (String) -> Void
    let onSubmit: () -> Void
    let onBack: () -> Void
    let onGoogle: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("Pick a magic name")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            TextField("Magic name", text: binding)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
            }
            Button("Continue") { onSubmit() }
                .disabled(uniqueName.isEmpty)
                .buttonStyle(GradientButtonStyle(gradient: .guestYellow))

            HStack {
                Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.25))
                Text("or").foregroundColor(.white.opacity(0.8))
                Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.25))
            }

            Button(action: onGoogle) {
                HStack {
                    Image(systemName: "g.circle.fill")
                    Text("Continue with Google")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())

            Button("← Back") { onBack() }
                .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var binding: Binding<String> {
        Binding(
            get: { uniqueName },
            set: onChange
        )
    }
}

private struct KidProfileDetailsView: View {
    let state: KidFlowState
    let onAvatarSelect: (KidAvatarOption) -> Void
    let onNameChange: (String) -> Void
    let onAgeChange: (String) -> Void
    let onSave: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Create a profile")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            KidAvatarBadge(option: state.selectedAvatar)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(KidAvatarOption.presets) { option in
                        KidAvatarChoice(option: option,
                                        isSelected: option.id == state.selectedAvatar.id,
                                        action: { onAvatarSelect(option) })
                    }
                }
                .padding(.vertical, 4)
            }

            TextField("Player name", text: Binding(
                get: { state.kidName },
                set: onNameChange
            ))
            .textFieldStyle(.roundedBorder)

            TextField("Age (3-15)", text: Binding(
                get: { state.kidAge },
                set: onAgeChange
            ))
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)

            if let error = state.profileError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
            }

            Button("Save profile") { onSave() }
                .disabled(state.kidName.isEmpty || state.kidAge.isEmpty)
                .buttonStyle(GradientButtonStyle(gradient: .loginPurple))

            Button("← Back") { onBack() }
                .buttonStyle(SecondaryButtonStyle())
        }
    }
}

private struct KidGreetingView: View {
    let profile: KidProfile?
    let onContinue: () -> Void
    let onSwitchProfile: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Welcome \(profile?.displayName ?? "friend")!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            if let profile {
                KidAvatarBadge(option: KidAvatarOption.option(for: profile))
                Text("Magic name: \(profile.uniqueName)")
                    .foregroundStyle(.white.opacity(0.85))
                Text("Age: \(profile.age)")
                    .foregroundStyle(.white.opacity(0.85))
            }
            Button("Continue") { onContinue() }
                .buttonStyle(GradientButtonStyle(gradient: .guestYellow))
            Button("Switch profile") { onSwitchProfile() }
                .buttonStyle(SecondaryButtonStyle())
        }
    }
}

private struct KidAvatarBadge: View {
    let option: KidAvatarOption

    var body: some View {
        Text(option.emoji)
            .font(.system(size: 48))
            .frame(width: 110, height: 110)
            .background(option.color.opacity(0.9), in: Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(radius: 8, y: 4)
    }
}

private struct KidAvatarChoice: View {
    let option: KidAvatarOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(option.emoji)
                .font(.system(size: 28))
                .frame(width: 56, height: 56)
                .background(option.color.opacity(0.9), in: Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                )
        }
        .buttonStyle(.plain)
        .shadow(radius: isSelected ? 6 : 2, y: 2)
    }
}

private struct KidStepIndicatorView: View {
    let currentStep: KidFlowStep

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(KidFlowStep.allCases.enumerated()), id: \.offset) { index, step in
                Circle()
                    .fill(step == currentStep ? AppColors.rainbowYellow : Color.white.opacity(0.3))
                    .frame(width: step == currentStep ? 16 : 10,
                           height: step == currentStep ? 16 : 10)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .animation(.spring(), value: currentStep)
            }
        }
    }
}
