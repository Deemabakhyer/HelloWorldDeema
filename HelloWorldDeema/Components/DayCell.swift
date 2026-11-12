//
//  DayCell.swift
//  HelloWorldDeema
//
//  Created by deema bakhyer on 12/11/2026.
//

import SwiftUI

public struct DayCell: View {
    let day: Date
    let status: DayStatus?
    let isToday: Bool

    public var body: some View {
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

