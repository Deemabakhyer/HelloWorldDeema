//
//  CalendarView.swift
//  HelloWorldDeema
//
//  Created by deema bakhyer on 11/11/2026.
//

import SwiftUI

// MARK: - Screen (iOS 26+)

struct CalendarView: View {
    let viewModel: ActivityViewModel

    var body: some View {
        let months = viewModel.calendarMonths

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(months.enumerated()), id: \.element) { index, month in
                        if index > 0 {
                            Divider().overlay(Color.white.opacity(0.12))
                        }
                        MonthSection(month: month, viewModel: viewModel)
                            .id(month)
                    }
                }
            }
            .onAppear {
                // Show every month, but open on the current one
                proxy.scrollTo(viewModel.currentMonth, anchor: .top)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Activities")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Month

private struct MonthSection: View {
    let month: Date
    let viewModel: ActivityViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols.map { $0.uppercased() }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(month, format: .dateTime.month(.wide).year())
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            // SUN MON TUE ...
            HStack(spacing: 0) {
                ForEach(weekdaySymbols.indices, id: \.self) { index in
                    Text(weekdaySymbols[index])
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(Array(viewModel.days(inMonth: month).enumerated()), id: \.offset) { _, day in
                    if let day {
                        DayCircle(
                            day: day,
                            status: viewModel.recordedStatus(on: day),
                            isToday: viewModel.isToday(day)
                        )
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
    }
}

// MARK: - Day

private struct DayCircle: View {
    let day: Date
    let status: DayStatus?
    let isToday: Bool

    var body: some View {
        Text(day, format: .dateTime.day())
            .font(.system(size: 17, weight: isToday && status == nil ? .semibold : .regular))
            .foregroundStyle(style.foreground)
            .frame(width: 36, height: 36)
            .background(Circle().fill(style.background))
            .frame(maxWidth: .infinity)
            .accessibilityLabel(accessibilityText)
    }

    private var style: (foreground: Color, background: Color) {
        switch status {
        case .learned: return (Color("Orange"), Color("Orange").opacity(0.18))
        case .frozen:  return (Color("Cyan"), Color("Cyan").opacity(0.18))
        case nil:
            return isToday ? (.white, Color("Orange")) : (.white, .clear)
        }
    }

    private var accessibilityText: String {
        let date = day.formatted(.dateTime.weekday(.wide).day().month(.wide))
        switch status {
        case .learned: return "\(date), learned"
        case .frozen:  return "\(date), freezed"
        case nil:      return date
        }
    }
}

// MARK: - Preview (Jan 1 → Mar 12, 2026, like the design)

private func previewViewModel() -> ActivityViewModel {
    let cal = Calendar(identifier: .gregorian)
    let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1))!
    let today = cal.date(from: DateComponents(year: 2026, month: 3, day: 12))!

    let frozenOffsets: Set<Int> = [50, 53, 61, 65, 66]     // Feb 20, Feb 23, Mar 3, Mar 7, Mar 8
    var seed: [Date: DayStatus] = [:]

    for offset in 0..<70 {
        guard let date = cal.date(byAdding: .day, value: offset, to: start), date < today else { break }
        if (11...29).contains(offset) { continue }          // Jan 12–30: nothing logged
        seed[date] = frozenOffsets.contains(offset) ? .frozen : .learned
    }

    let goal = Goal(subject: "Swift", startDate: start, targetDays: 365)
    return ActivityViewModel(now: { today }, seed: seed, goal: goal)
}

#Preview {
    NavigationStack {
        CalendarView(viewModel: previewViewModel())
    }
}
