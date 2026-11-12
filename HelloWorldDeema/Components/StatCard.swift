//
//  StatCard.swift
//  HelloWorldDeema
//
//  Created by deema bakhyer on 12/11/2026.
//

import SwiftUI

public struct StatCard: View {
    let icon: String
    let tint: Color
    let count: Int
    let label: String

    public var body: some View {
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
