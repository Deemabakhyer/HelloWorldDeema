//
//  ActivityViewModel.swift
//  HelloWorldDeema
//
//  Created by deema bakhyer on 11/11/2026.
//

import Foundation
import SwiftData

// MARK: - ViewModel

/// Single source of truth shared by every screen.
/// Keeps an in-memory copy (`entries`, `goal`) for fast, observable UI updates and
/// writes every change through to SwiftData.
@MainActor
@Observable
final class ActivityViewModel {

    private(set) var today: Date
    private(set) var entries: [String: DayStatus]
    private(set) var goal: Goal

    private let calendar: Calendar
    private let now: () -> Date
    private let context: ModelContext?

    /// - Parameters:
    ///   - seed: pre-filled days (previews/tests). When nil, days are loaded from SwiftData.
    ///   - goal: pre-set goal (previews/tests). When nil, the newest saved goal is loaded.
    ///   - context: SwiftData context used to load and save. Pass nil to keep everything in memory.
    init(
        now: @escaping () -> Date = { .now },
        seed: [Date: DayStatus]? = nil,
        goal: Goal? = nil,
        context: ModelContext? = nil
    ) {
        var cal = Calendar.current
        cal.firstWeekday = 1                      // week starts on Sunday, like the design
        let startOfToday = cal.startOfDay(for: now())

        self.calendar = cal
        self.now = now
        self.today = startOfToday
        self.context = context

        var loadedEntries: [String: DayStatus] = [:]
        var loadedGoal: Goal?

        if let seed {
            loadedEntries = Dictionary(
                seed.map { (Self.key(for: $0.key, calendar: cal), $0.value) },
                uniquingKeysWith: { $1 }
            )
        } else if let context {
            Self.migrateLegacyDataIfNeeded(into: context)
            loadedEntries = Self.fetchEntries(from: context)
            loadedGoal = Self.fetchLatestGoal(from: context)
        }

        self.entries = loadedEntries
        self.goal = goal ?? loadedGoal ?? Goal(subject: "Swift", startDate: startOfToday, targetDays: 7)
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

    // MARK: Calendar (full history)

    /// Status of any day ever recorded, regardless of which goal it belonged to.
    func recordedStatus(on date: Date) -> DayStatus? {
        entries[Self.key(for: date, calendar: calendar)]
    }

    /// First day of the month that contains today.
    var currentMonth: Date {
        calendar.dateInterval(of: .month, for: today)!.start
    }

    /// Every month of every year in use: from January of the earliest year
    /// (first recorded entry, or the current year) through December of the current year.
    var calendarMonths: [Date] {
        var earliest = today

        if let earliestKey = entries.keys.min() {
            let parts = earliestKey.split(separator: "-").compactMap { Int($0) }
            if parts.count == 3,
               let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) {
                earliest = min(earliest, date)
            }
        }

        let startYear = calendar.component(.year, from: earliest)
        let endYear = calendar.component(.year, from: today)

        guard let first = calendar.date(from: DateComponents(year: startYear, month: 1, day: 1)),
              let last = calendar.date(from: DateComponents(year: endYear, month: 12, day: 1))
        else { return [currentMonth] }

        var months: [Date] = []
        var cursor = first
        while cursor <= last {
            months.append(cursor)
            cursor = calendar.date(byAdding: .month, value: 1, to: cursor)!
        }
        return months
    }

    /// Days of a month laid out Sunday-first; leading `nil`s are the empty cells before the 1st.
    func days(inMonth month: Date) -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: month)!
        let weekdayOfFirst = calendar.component(.weekday, from: month)       // 1 = Sunday
        let leading = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let days: [Date?] = range.map { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
        return Array<Date?>(repeating: nil, count: leading) + days
    }

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
    /// Earlier goals stay in storage as history.
    func startNewGoal(subject: String, targetDays: Int) {
        let todayKey = Self.key(for: today, calendar: calendar)
        let newGoal = Goal(subject: subject, startDate: today, targetDays: targetDays)

        entries[todayKey] = nil
        goal = newGoal

        guard let context else { return }
        if let record = record(for: todayKey) { context.delete(record) }
        context.insert(GoalRecord(goal: newGoal))
        saveContext()
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

    /// Updates memory first (instant UI), then writes through to SwiftData.
    private func set(_ status: DayStatus, on date: Date) {
        let key = Self.key(for: date, calendar: calendar)
        entries[key] = status

        guard let context else { return }
        if let existing = record(for: key) {
            existing.status = status
        } else {
            context.insert(DayEntryRecord(dayKey: key, status: status))
        }
        saveContext()
    }

    private static func key(for date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    // MARK: SwiftData

    private func record(for key: String) -> DayEntryRecord? {
        guard let context else { return nil }
        var descriptor = FetchDescriptor<DayEntryRecord>(
            predicate: #Predicate { $0.dayKey == key }
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    private func saveContext() {
        do {
            try context?.save()
        } catch {
            print("Failed to save activity data: \(error)")
        }
    }

    private static func fetchEntries(from context: ModelContext) -> [String: DayStatus] {
        let records = (try? context.fetch(FetchDescriptor<DayEntryRecord>())) ?? []
        return Dictionary(records.map { ($0.dayKey, $0.status) }, uniquingKeysWith: { $1 })
    }

    /// The newest goal is the current one; older goals remain as history.
    private static func fetchLatestGoal(from context: ModelContext) -> Goal? {
        var descriptor = FetchDescriptor<GoalRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first?.goal
    }

    // MARK: Legacy migration (UserDefaults → SwiftData)

    /// Earlier versions saved days and the goal as JSON in UserDefaults.
    /// If SwiftData is still empty, import that data once and remove the old keys.
    private static func migrateLegacyDataIfNeeded(into context: ModelContext) {
        let hasStoredData =
            ((try? context.fetchCount(FetchDescriptor<DayEntryRecord>())) ?? 0) > 0 ||
            ((try? context.fetchCount(FetchDescriptor<GoalRecord>())) ?? 0) > 0
        guard !hasStoredData else { return }

        let defaults = UserDefaults.standard
        let decoder = JSONDecoder()
        let entriesKey = "activity.entries"
        let goalKey = "activity.goal"

        if let data = defaults.data(forKey: entriesKey),
           let saved = try? decoder.decode([String: DayStatus].self, from: data) {
            for (key, status) in saved {
                context.insert(DayEntryRecord(dayKey: key, status: status))
            }
        }

        if let data = defaults.data(forKey: goalKey),
           let saved = try? decoder.decode(Goal.self, from: data) {
            context.insert(GoalRecord(goal: saved))
        }

        try? context.save()
        defaults.removeObject(forKey: entriesKey)
        defaults.removeObject(forKey: goalKey)
    }
}
