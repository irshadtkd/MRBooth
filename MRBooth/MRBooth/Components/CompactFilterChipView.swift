//
//  CompactFilterChipView.swift
//  MRBooth
//

import SwiftUI

struct CompactFilterChipView: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.caption(.semibold))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(color.opacity(isSelected ? 0 : 0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
