//
//  HeaderIconButton.swift
//  HelloWorldDeema
//
//  Created by deema bakhyer on 12/11/2026.
//

import SwiftUI

public struct HeaderIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }
}
