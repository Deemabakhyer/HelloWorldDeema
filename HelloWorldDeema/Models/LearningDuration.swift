//
//  LearningDuration.swift
//  HelloWorldDeema
//
//  Created by deema bakhyer on 10/11/2026.
//

enum LearningDuration: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }
}
/// Uses the `LearningDuration` enum from the onboarding screen.
extension LearningDuration {
    var days: Int {
        switch self {
        case .week:  return 7
        case .month: return 30
        case .year:  return 365
        }
    }

    static func closest(toDays days: Int) -> LearningDuration {
        days <= 7 ? .week : (days <= 31 ? .month : .year)
    }
}

