//
//  StatCardView.swift
//  MRBooth
//

import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(AppFonts.statNumber())
                .foregroundStyle(AppTheme.textPrimary)
            Text(title)
                .font(AppFonts.caption())
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(AppTheme.paddingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
        .shadow(color: .black.opacity(AppTheme.shadowOpacity), radius: 4, y: 2)
    }
}
