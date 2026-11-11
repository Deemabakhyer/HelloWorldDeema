//
//  Home.swift
//  MyApp
//
//  Created by deema bakhyer on 09/11/2026.
//

import SwiftUI

// MARK: - Screen (iOS 26+, Liquid Glass)

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: HomeViewModel = HomeViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                weekStrip.padding(.top, 14)
                statCards.padding(.top, 14)

                Spacer(minLength: 16)
                logButton
                Spacer(minLength: 16)

                freezeSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.success, trigger: viewModel.todayStatus)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.refreshToday() }
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
                        // TODO: present learning-goal editor
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

// MARK: - Components

private struct HeaderIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }
}

private struct DayCell: View {
    let day: Date
    let status: DayStatus?
    let isToday: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text(day, format: .dateTime.weekday(.narrow))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))

            Text(day, format: .dateTime.day())
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(style.foreground)
                .frame(width: 40, height: 40)
                .background(Circle().fill(style.background))
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(duration: 0.4, bounce: 0.2), value: status)
    }

    private var style: (foreground: Color, background: Color) {
        switch status {
        case .learned: return (Color("Orange"), Color("Orange").opacity(0.18))
        case .frozen:  return (Color("Cyan"), Color("Cyan").opacity(0.18))
        case nil:
            return isToday ? (.black, Color("Orange")) : (.white, .clear)
        }
    }
}

private struct StatCard: View {
    let icon: String
    let tint: Color
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(tint)

            Text("^[\(count) day](inflect: true)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .glassEffect(.regular, in: .rect(cornerRadius: 26))
        .animation(.spring(duration: 0.4, bounce: 0.2), value: count)
    }
}

// MARK: - Preview data (matches the 4 states in the design)
//
//private extension HomeViewModel {
//    static func mock(past: [Int: DayStatus], today todayStatus: DayStatus?) -> HomeViewModel {
//        let cal = Calendar(identifier: .gregorian)
//        let date = cal.date(from: DateComponents(year: 2024, month: 10, day: 24))!   // Thursday 24 October
//
//        var seed: [Date: DayStatus] = [:]
//        for (offset, status) in past {
//            seed[cal.date(byAdding: .day, value: offset, to: date)!] = status
//        }
//        if let todayStatus { seed[date] = todayStatus }
//
//        return HomeViewModel(now: { date }, seed: seed, persistenceKey: nil)
//    }
//}

private let fourLearned: [Int: DayStatus] = [-4: .learned, -3: .learned, -2: .learned, -1: .learned]

#Preview("Default") {
    HomeView()
}

//#Preview("Default") {
//    HomeView(viewModel: .mock(past: fourLearned, today: nil))
//}
//
//#Preview("Learned today") {
//    HomeView(viewModel: .mock(past: fourLearned, today: .learned))
//}
//
//#Preview("Freezed today") {
//    HomeView(viewModel: .mock(past: fourLearned, today: .frozen))
//}
//
//#Preview("No freezes available") {
//    HomeView(viewModel: .mock(
//        past: [-4: .learned, -3: .learned, -2: .learned, -1: .frozen],
//        today: .frozen
//    ))
//}
