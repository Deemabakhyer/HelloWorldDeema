//
//  ActivityViewModel.swift
//  HelloWorldDeema
//
//  Created by deema bakhyer on 11/11/2026.
//

import Foundation

// MARK: - ViewModel

@Observable
final class ActivityViewModel {

    private(set) var today: Date
    private(set) var entries: [String: DayStatus]
    private(set) var goal: Goal

    private let calendar: Calendar
    private let now: () -> Date
    private let persistenceKey: String?

    /// - Parameters:
    ///   - seed: pre-filled days (previews/tests). When nil, data is loaded from UserDefaults.
    ///   - goal: pre-set goal (previews/tests). When nil, it is loaded from UserDefaults.
    ///   - persistenceKey: base key for saving ("<key>.entries" and "<key>.goal"). Pass nil to disable saving.
    init(
        now: @escaping () -> Date = { .now },
        seed: [Date: DayStatus]? = nil,
        goal: Goal? = nil,
        persistenceKey: String? = "activity"
    ) {
        var cal = Calendar.current
        cal.firstWeekday = 1                      // week starts on Sunday, like the design
        let startOfToday = cal.startOfDay(for: now())

        self.calendar = cal
        self.now = now
        self.today = startOfToday
        self.persistenceKey = persistenceKey

        let defaults = UserDefaults.standard
        let decoder = JSONDecoder()

        // Entries
        if let seed {
            self.entries = Dictionary(
                seed.map { (Self.key(for: $0.key, calendar: cal), $0.value) },
                uniquingKeysWith: { $1 }
            )
        } else if let persistenceKey,
                  let data = defaults.data(forKey: "\(persistenceKey).entries"),
                  let saved = try? decoder.decode([String: DayStatus].self, from: data) {
            self.entries = saved
        } else {
            self.entries = [:]
        }

        // Goal
        if let goal {
            self.goal = goal
        } else if let persistenceKey,
                  let data = defaults.data(forKey: "\(persistenceKey).goal"),
                  let saved = try? decoder.decode(Goal.self, from: data) {
            self.goal = saved
        } else {
            self.goal = Goal(subject: "Swift", startDate: startOfToday, targetDays: 7)
        }
    }

    // MARK: Derived state

    var maxFreezes: Int { goal.maxFreezes }

    /// The 7 days (Sun–Sat) of the current week.
    var weekDays: [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: today)!.start
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: start)! }
    }

    /// Progress of the current goal.
    var goalState: GoalState {
        var covered = 0
        for offset in 0..<goal.targetDays {
            let day = calendar.date(byAdding: .day, value: offset, to: goal.startDate)!
            if day > today { break }                       // future days
            if status(on: day) != nil {
                covered += 1                               // learned or frozen
            } else if day < today {
                return .failed                             // missed a past day
            } else {
                break                                      // today, not logged yet
            }
        }
        return covered >= goal.targetDays ? .completed : .active
    }

    var todayStatus: DayStatus? { status(on: today) }
    var isLoggedToday: Bool { todayStatus == .learned }

    var learnedCount: Int { count(of: .learned) }
    var frozenCount: Int { count(of: .frozen) }
    var freezesUsed: Int { frozenCount }

    /// Freeze is available while the goal is active, unless today is already frozen
    /// or every freeze is used.
    var canFreeze: Bool {
        goalState == .active && todayStatus != .frozen && freezesUsed < maxFreezes
    }

    /// Days before the goal started are ignored.
    func status(on date: Date) -> DayStatus? {
        guard date >= goal.startDate else { return nil }
        return entries[Self.key(for: date, calendar: calendar)]
    }

    func isToday(_ date: Date) -> Bool { calendar.isDate(date, inSameDayAs: today) }
    func isFuture(_ date: Date) -> Bool { date > today }

    // MARK: Actions

    /// Marks today as learned. If today was frozen, the freeze is given back automatically
    /// because the counts are derived from the entries.
    func logLearned() {
        guard goalState == .active, !isLoggedToday else { return }
        set(.learned, on: today)
    }

    func freezeToday() {
        guard canFreeze else { return }
        set(.frozen, on: today)
    }

    /// Starts a new goal today (use the same subject/duration to "set the same goal again").
    /// Today's old entry is cleared so the new goal starts with a fresh day.
    func startNewGoal(subject: String, targetDays: Int) {
        entries[Self.key(for: today, calendar: calendar)] = nil
        goal = Goal(subject: subject, startDate: today, targetDays: targetDays)
        save()
    }

    /// Call when the app returns to the foreground so a new day is picked up.
    func refreshToday() {
        let newToday = calendar.startOfDay(for: now())
        if newToday != today { today = newToday }
    }

    // MARK: Helpers

    private func count(of status: DayStatus) -> Int {
        (0..<goal.targetDays)
            .compactMap { calendar.date(byAdding: .day, value: $0, to: goal.startDate) }
            .filter { self.status(on: $0) == status }
            .count
    }

    private func set(_ status: DayStatus, on date: Date) {
        entries[Self.key(for: date, calendar: calendar)] = status
        save()
    }

    private func save() {
        guard let persistenceKey else { return }
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: "\(persistenceKey).entries")
        }
        if let data = try? JSONEncoder().encode(goal) {
            defaults.set(data, forKey: "\(persistenceKey).goal")
        }
    }

    private static func key(for date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
