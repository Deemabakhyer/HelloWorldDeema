//
//  StorageModels.swift
//  HelloWorldDeema
//
//  Created by deema bakhyer on 17/11/2026.
//

import Foundation
import SwiftData

// MARK: - One logged day

@Model
final class DayEntryRecord {
    /// "yyyy-MM-dd" — unique, so saving the same day twice updates it instead of duplicating it.
    @Attribute(.unique) var dayKey: String
    var statusRaw: String

    init(dayKey: String, status: DayStatus) {
        self.dayKey = dayKey
        self.statusRaw = status.rawValue
    }

    var status: DayStatus {
        get { DayStatus(rawValue: statusRaw) ?? .learned }
        set { statusRaw = newValue.rawValue }
    }
}

// MARK: - One learning goal (the newest one is the current goal)

@Model
final class GoalRecord {
    var subject: String
    var startDate: Date
    var targetDays: Int
    var createdAt: Date

    init(subject: String, startDate: Date, targetDays: Int, createdAt: Date = .now) {
        self.subject = subject
        self.startDate = startDate
        self.targetDays = targetDays
        self.createdAt = createdAt
    }

    convenience init(goal: Goal) {
        self.init(subject: goal.subject, startDate: goal.startDate, targetDays: goal.targetDays)
    }

    /// The value type the view model works with.
    var goal: Goal {
        Goal(subject: subject, startDate: startDate, targetDays: targetDays)
    }
}
