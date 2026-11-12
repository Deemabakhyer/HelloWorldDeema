//
//  ActivityView.swift
//  MyApp
//
//  Created by deema bakhyer on 09/11/2026.
//

import SwiftUI

// MARK: - Screen (iOS 26+, Liquid Glass)

struct ActivityView: View {
    @State private var viewModel: ActivityViewModel
    @State private var showGoalEditor = false
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: ActivityViewModel = ActivityViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            screen
                .navigationDestination(isPresented: $showGoalEditor) {
                    UpdateGoalView(
                        subject: viewModel.goal.subject,
                        duration: .closest(toDays: viewModel.goal.targetDays),
                        warnsStreakReset: viewModel.goalState == .active
                    ) { subject, duration in
                        withAnimation(.spring(duration: 0.45, bounce: 0.2)) {
                            viewModel.startNewGoal(subject: subject, targetDays: duration.days)
                        }
                    }
                }
        }
    }

    private var screen: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                weekStrip.padding(.top, 14)
                statCards.padding(.top, 14)

                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.success, trigger: viewModel.todayStatus)
        .animation(.spring(duration: 0.45, bounce: 0.2), value: viewModel.goalState)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.refreshToday() }
        }
//        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Switchable content (in progress vs. goal result)

    @ViewBuilder
    private var content: some View {
        switch viewModel.goalState {
        case .active:
            VStack(spacing: 0) {
                Spacer(minLength: 16)
                logButton
                Spacer(minLength: 16)
                freezeSection
            }
            .transition(.opacity)

        case .completed, .failed:
            VStack(spacing: 0) {
                Spacer()
                GoalResultSection(isCompleted: viewModel.goalState == .completed) {
                    showGoalEditor = true
                }
                Spacer()
                Spacer()
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Activity")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)

                Text(Self.dateFormatter.string(from: viewModel.today))
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }

            Spacer()

            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    HeaderIconButton(systemName: "calendar", label: "Calendar") {
                        // TODO: present the full calendar
                    }
                    HeaderIconButton(systemName: "pencil.and.outline", label: "Edit goal") {
                        showGoalEditor = true
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: Week strip

    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.weekDays, id: \.self) { day in
                DayCell(
                    day: day,
                    status: viewModel.status(on: day),
                    isToday: viewModel.isToday(day)
                )
            }
        }
    }

    // MARK: Stat cards

    private var statCards: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "flame.fill",
                tint: Color("Orange"),
                count: viewModel.learnedCount,
                label: "Learned"
            )
            StatCard(
                icon: "snowflake",
                tint: Color("Cyan"),
                count: viewModel.frozenCount,
                label: "Freezed"
            )
        }
    }

    // MARK: Big log button

    private var logButton: some View {
        let logged = viewModel.isLoggedToday

        return Button {
            withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                viewModel.logLearned()
            }
        } label: {
            Text(logged ? "Logged as Learned" : "Log as Learned")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(logged ? Color.white.opacity(0.35) : .white)
                .frame(width: 272, height: 272)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(
            logged ? .regular : .regular.tint(Color("Orange")).interactive(),
            in: .circle
        )
        .disabled(logged)
        .animation(.spring(duration: 0.4, bounce: 0.2), value: logged)
    }

    // MARK: Freeze

    private var freezeSection: some View {
        let canFreeze = viewModel.canFreeze

        return VStack(spacing: 14) {
            Button {
                withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                    viewModel.freezeToday()
                }
            } label: {
                Text("Freeze for a day")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(canFreeze ? .white : Color.white.opacity(0.3))
                    .frame(width: 272, height: 48)
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .glassEffect(
                canFreeze ? .regular.tint(Color("Cyan")).interactive() : .regular,
                in: .capsule
            )
            .disabled(!canFreeze)

            Text("\(viewModel.freezesUsed) out of \(viewModel.maxFreezes) Freezes used")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
        }
        .animation(.spring(duration: 0.4, bounce: 0.2), value: canFreeze)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"          // "Thursday, 24 October"
        return f
    }()
}

// MARK: - Goal result (completed / not met)

private struct GoalResultSection: View {
    let isCompleted: Bool
    let onSetGoal: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: isCompleted ? "hands.sparkles.fill" : "xmark.seal.fill")
                .font(.system(size: 46))
                .foregroundStyle(Color("Orange"))
                .symbolRenderingMode(.monochrome)
                .padding(.bottom, 16)

            Text(isCompleted ? "Well done!" : "You didn't reach your goal this time.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(isCompleted ? "Ready for your next goal?" : "Want to set another goal?")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
                .padding(.top, 4)

            Button(action: onSetGoal) {
                Label("Set a goal", systemImage: "pencil.and.outline")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .frame(height: 48)
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.tint(Color("Orange")).interactive(), in: .capsule)
            .padding(.top, 64)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview data (to check every state without waiting for real days)

private extension ActivityViewModel {
    /// Fixed date: Thursday 24 October. The goal starts on Sunday 20 October.
    static func mock(
        past: [Int: DayStatus],
        today todayStatus: DayStatus?,
        targetDays: Int = 7
    ) -> ActivityViewModel {
        let cal = Calendar(identifier: .gregorian)
        let date = cal.date(from: DateComponents(year: 2024, month: 10, day: 24))!

        var seed: [Date: DayStatus] = [:]
        for (offset, status) in past {
            seed[cal.date(byAdding: .day, value: offset, to: date)!] = status
        }
        if let todayStatus { seed[date] = todayStatus }

        let goal = Goal(
            subject: "Swift",
            startDate: cal.date(byAdding: .day, value: -4, to: date)!,
            targetDays: targetDays
        )
        return ActivityViewModel(now: { date }, seed: seed, goal: goal, persistenceKey: nil)
    }
}

#Preview("Default") {
    ActivityView()
}

#Preview("Goal completed") {
    ActivityView(viewModel: .mock(
        past: [-4: .learned, -3: .learned, -2: .learned, -1: .frozen],
        today: .frozen,
        targetDays: 5
    ))
}

#Preview("Goal not met") {
    ActivityView(viewModel: .mock(
        past: [-4: .learned, -3: .learned, -1: .frozen],   // 22 Oct missed
        today: .frozen,
        targetDays: 5
    ))
}
