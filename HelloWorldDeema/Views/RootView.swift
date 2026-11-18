//
//  RootView.swift
//
//  Shows onboarding on first launch, then the Activity screen.
//

import SwiftUI

struct RootView: View {
    /// Remembered between launches so onboarding only appears once.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    /// One shared view model (created in the App, backed by SwiftData):
    /// onboarding creates the goal, Activity and the other screens display it.
    let viewModel: ActivityViewModel

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                ActivityView(viewModel: viewModel)
                    .transition(.opacity)
            } else {
                OnboardingView { subject, duration in
                    viewModel.startNewGoal(subject: subject, targetDays: duration.days)
                    withAnimation(.easeInOut(duration: 0.4)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    RootView(viewModel: ActivityViewModel())
}
