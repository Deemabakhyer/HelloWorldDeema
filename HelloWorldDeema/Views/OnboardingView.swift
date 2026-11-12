//
//  OnboardingView.swift
//  MyApp
//
//  Created by deema bakhyer on 09/11/2026.
//

import SwiftUI

// MARK: - View (iOS 26+, Liquid Glass)

struct OnboardingView: View {
    @State private var subject = ""
    @State private var duration: LearningDuration = .week
    @FocusState private var isFocused: Bool

    private var greeting: AttributedString {
        var hello = AttributedString("Hello ")
        hello.font = .system(size: 34, weight: .light)

        var name = AttributedString("Learner")
        name.font = .system(size: 34, weight: .bold)

        return hello + name
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // Flame logo
                HStack {
                    Spacer()
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color("Orange")
                        )
                    Spacer()
                }
                .padding(.top, 64)

                // Title
                Text(greeting)
                    .foregroundStyle(.white)
                    .padding(.top, 70)

                Text("This app will help you learn everyday!")
                    .font(.system(size: 17))
                    .foregroundStyle(.gray)
                    .padding(.top, 2)

                // Subject
                Text("I want to learn")
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .padding(.top, 28)

                TextField(
                    "",
                    text: $subject,
                    prompt: Text("Swift").foregroundColor(Color.white.opacity(0.28))
                )
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .tint(Color("Orange"))
                .focused($isFocused)
                .padding(.top, 18)

                Divider()
                    .overlay(Color.white.opacity(0.15))
                    .padding(.top, 12)

                // Duration
                Text("I want to learn it in a")
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .padding(.top, 28)

                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        ForEach(LearningDuration.allCases) { item in
                                DurationChip(
                                title: item.rawValue,
                                isSelected: duration == item,
                                accent: Color("Orange")
                            ) {
                                withAnimation(.spring(duration: 0.35, bounce: 0.25)) {
                                    duration = item
                                }
                            }
                        }
                    }
                }
                .padding(.top, 14)

                Spacer()

                // Bottom CTA
                VStack(spacing: 14) {
                    Button {
                        // Start learning action
                    } label: {
                        Text("Start Learning")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color("Orange"))

                    Text("You can edit your desire later")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 17)
        }
        .preferredColorScheme(.dark)
        .onTapGesture { isFocused = false }
    }
}
// MARK: - Preview

#Preview {
    OnboardingView()
}
