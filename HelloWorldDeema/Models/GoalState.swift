//
//  GoalState.swift
//  HelloWorldDeema
//
//  Created by deema bakhyer on 12/11/2026.
//

import Foundation

// MARK: - Goal models

enum GoalState {
    case active      // still in progress → show Log / Freeze buttons
    case completed   // every day of the goal was learned or frozen
    case failed      // a day was missed → streak broken
}

struct Goal: Codable, Equatable {
    var subject: String
    var startDate: Date
    var targetDays: Int

    /// Freezes allowed for this goal (week → 2, month → 6, year → 12).
    var maxFreezes: Int {
        switch targetDays {
        case ...7:  return 2
        case ...31: return 6
        default:    return 12
        }
    }
}
