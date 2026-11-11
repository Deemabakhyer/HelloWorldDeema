//
//  DurationChip.swift
//  HelloWorldDeema
//
//  Created by deema bakhyer on 10/11/2026.
//

import SwiftUI

public struct DurationChip: View {
    let title: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isSelected ? .white : Color.white.opacity(0.35))
                .frame(minWidth: 56)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected
                ? .regular.tint(accent).interactive()
                : .regular.tint(Color.white.opacity(0.04)).interactive(),
            in: .capsule
        )
    }
}
