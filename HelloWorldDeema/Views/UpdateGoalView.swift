//
//  UpdateGoalView.swift
//  HelloWorldDeema
//
//  Created by deema bakhyer on 12/11/2026.
//

import SwiftUI

// MARK: - Screen (iOS 26+, Liquid Glass)

struct UpdateGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    @State private var subject: String
    @State private var duration: LearningDuration
    @State private var showUpdateAlert = false

    private let originalSubject: String
    private let originalDuration: LearningDuration
    private let warnsStreakReset: Bool
    private let onUpdate: (String, LearningDuration) -> Void

    /// - Parameters:
    ///   - warnsStreakReset: `true` while a goal is in progress → changing it shows the
    ///     "your streak will start over" alert. `false` after a goal ended (completed / not met),
    ///     where there is no streak to lose, so the goal is set right away (even if unchanged).
    ///   - onUpdate: called with the new subject and duration when the user confirms.
    init(
        subject: String,
        duration: LearningDuration,
        warnsStreakReset: Bool = true,
        onUpdate: @escaping (String, LearningDuration) -> Void
    ) {
        _subject = State(initialValue: subject)
        _duration = State(initialValue: duration)
        originalSubject = subject
        originalDuration = duration
        self.warnsStreakReset = warnsStreakReset
        self.onUpdate = onUpdate
    }

    private var trimmedSubject: String {
        subject.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasChanges: Bool {
        trimmedSubject != originalSubject || duration != originalDuration
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .onTapGesture { isFocused = false }

            VStack(alignment: .leading, spacing: 0) {

                // Subject
                Text("I want to learn")
                    .font(.system(size: 17))
                    .foregroundStyle(.white)

                TextField(
                    "",
                    text: $subject,
                    prompt: Text("Swift").foregroundColor(Color.white.opacity(0.28))
                )
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .tint(Color("Orange"))
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit { isFocused = false }
                .padding(.top, 16)

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
                                isSelected: duration == item, accent: Color("Orange")
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
        }
        .navigationTitle("Learning Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                // System checkmark in a prominent Liquid Glass button
                Button(role: .confirm) {
                    confirm()
                }
                .tint(Color("Orange"))
                .disabled(trimmedSubject.isEmpty)
            }
        }
        .alert("Update goal", isPresented: $showUpdateAlert) {
            Button("Dismiss", role: .cancel) { }
            Button("Update") { apply() }
        } message: {
            Text("If you update now, your streak will start over.")
        }
        .tint(Color("Orange"))
        .preferredColorScheme(.dark)
    }

    // MARK: Actions

    private func confirm() {
        isFocused = false

        guard warnsStreakReset else {
            apply()                     // goal already ended → nothing to lose
            return
        }

        if hasChanges {
            showUpdateAlert = true      // goal in progress → warn first
        } else {
            dismiss()                   // nothing changed → just go back
        }
    }

    private func apply() {
        onUpdate(trimmedSubject, duration)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UpdateGoalView(subject: "Swift", duration: .week) { _, _ in }
    }
}
