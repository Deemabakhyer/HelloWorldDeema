//
//  File.swift
//  HelloWorldDeema
//
//  Created by deema bakhyer on 11/11/2026.
//

import Foundation

// MARK: - ViewModel

@Observable
final class HomeViewModel {

    private(set) var today: Date
    private(set) var entries: [String: DayStatus]
    let maxFreezes: Int

    private let calendar: Calendar
    private let now: () -> Date
    private let persistenceKey: String?

    /// - Parameters:
    ///   - seed: pre-filled days (used by previews/tests). When nil, data is loaded from UserDefaults.
    ///   - persistenceKey: pass nil to disable saving.
    init(
        now: @escaping () -> Date = { .now },
        seed: [Date: DayStatus]? = nil,
        persistenceKey: String? = "activity.entries",
        maxFreezes: Int = 2
    ) {
        var cal = Calendar.current
        cal.firstWeekday = 1                      // week starts on Sunday, like the design
        self.calendar = cal
        self.now = now
        self.today = cal.startOfDay(for: now())
        self.maxFreezes = maxFreezes
        self.persistenceKey = persistenceKey

        if let seed {
            self.entries = Dictionary(
                seed.map { (Self.key(for: $0.key, calendar: cal), $0.value) },
                uniquingKeysWith: { $1 }
            )
        } else if let persistenceKey,
                  let data = UserDefaults.standard.data(forKey: persistenceKey),
                  let saved = try? JSONDecoder().decode([String: DayStatus].self, from: data) {
            self.entries = saved
        } else {
            self.entries = [:]
        }
    }

    // MARK: Derived state

    /// The 7 days (Sun–Sat) of the current week.
    var weekDays: [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: today)!.start
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: start)! }
    }

    var todayStatus: DayStatus? { status(on: today) }
    var isLoggedToday: Bool { todayStatus == .learned }

    var learnedCount: Int { count(of: .learned) }
    var frozenCount: Int { count(of: .frozen) }
    var freezesUsed: Int { frozenCount }

    /// Freeze is available unless today is already frozen or every freeze is used.
    var canFreeze: Bool { todayStatus != .frozen && freezesUsed < maxFreezes }

    func status(on date: Date) -> DayStatus? {
        entries[Self.key(for: date, calendar: calendar)]
    }

    func isToday(_ date: Date) -> Bool { calendar.isDate(date, inSameDayAs: today) }
    func isFuture(_ date: Date) -> Bool { date > today }

    // MARK: Actions

    /// Marks today as learned. If today was frozen, the freeze is given back automatically
    /// because the counts are derived from the entries.
    func logLearned() {
        guard !isLoggedToday else { return }
        set(.learned, on: today)
    }

    func freezeToday() {
        guard canFreeze else { return }
        set(.frozen, on: today)
    }

    /// Call when the app returns to the foreground so a new day is picked up.
    func refreshToday() {
        let newToday = calendar.startOfDay(for: now())
        if newToday != today { today = newToday }
    }

    // MARK: Helpers

    private func count(of status: DayStatus) -> Int {
        weekDays.filter { self.status(on: $0) == status }.count
    }

    private func set(_ status: DayStatus, on date: Date) {
        entries[Self.key(for: date, calendar: calendar)] = status
        save()
    }

    private func save() {
        guard let persistenceKey, let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

    private static func key(for date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
