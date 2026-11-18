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
        // Custom alert (the native one can't have a filled orange button / left-aligned text).
        // Shown full screen over a dimmed background so it also dims the navigation bar.
        .fullScreenCover(isPresented: $showUpdateAlert) {
            UpdateGoalAlert(
                onDismiss: { setAlert(false) },
                onUpdate: {
                    setAlert(false)
                    // Wait for the alert to close, then apply and go back
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(150))
                        apply()
                    }
                }
            )
            .presentationBackground(.black.opacity(0.6))
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
            setAlert(true)              // goal in progress → warn first
        } else {
            dismiss()                   // nothing changed → just go back
        }
    }

    private func apply() {
        onUpdate(trimmedSubject, duration)
        dismiss()
    }

    /// Presents / hides the alert without the full-screen cover's slide animation
    /// (the card fades and scales in by itself instead).
    private func setAlert(_ shown: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            showUpdateAlert = shown
        }
    }
}

// MARK: - Alert card (matches the design: left-aligned text, Dismiss + orange Update)

private struct UpdateGoalAlert: View {
    let onDismiss: () -> Void
    let onUpdate: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Update goal")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Text("If you update now, your streak will start over.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)

            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    // Dismiss: neutral glass
                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.tint(Color.white.opacity(0.12)).interactive(), in: .capsule)

                    // Update: filled orange
                    Button(action: onUpdate) {
                        Text("Update")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.tint(Color("Orange")).interactive(), in: .capsule)
                }
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: 320, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 30))
        .padding(.horizontal, 40)
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UpdateGoalView(subject: "Swift", duration: .week) { _, _ in }
    }
}

#Preview("Alert") {
    ZStack {
        Color.black.ignoresSafeArea()
        UpdateGoalAlert(onDismiss: {}, onUpdate: {})
    }
}
