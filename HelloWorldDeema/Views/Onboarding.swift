//
//  Onboarding.swift
//  MyApp
//
//  Created by deema bakhyer on 09/11/2026.
//

import SwiftUI

// MARK: - Model

enum LearningDuration: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }
}

// MARK: - View (iOS 26+, Liquid Glass)

struct OnboardingView: View {
    @State private var subject = ""
    @State private var duration: LearningDuration = .week
    @FocusState private var isFocused: Bool

    private let accent = Color(red: 0.96, green: 0.55, blue: 0.13) // #F58C21

    // Mixed-weight title built with AttributedString (replaces deprecated Text + Text)
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
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.68, blue: 0.25), accent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
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
                .tint(accent)
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
                                accent: accent
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
                    .tint(accent)

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

// MARK: - Chip

private struct DurationChip: View {
    let title: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isSelected ? .white : Color.white.opacity(0.35))
                .frame(minWidth: 56)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected
                ? .regular.tint(accent).interactive()
                : .regular.tint(Color.white.opacity(0.04)).interactive(),
            in: .capsule
        )
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
