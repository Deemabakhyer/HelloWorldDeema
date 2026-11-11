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
