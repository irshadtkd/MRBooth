//
//  View+Extensions.swift
//  MRBooth
//

import SwiftUI

extension View {
    func cardStyle(padding: CGFloat = AppTheme.paddingMedium) -> some View {
        self
            .padding(padding)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
            .shadow(color: .black.opacity(AppTheme.shadowOpacity), radius: AppTheme.shadowRadius, y: 2)
    }

    func primaryButtonStyle() -> some View {
        self
            .font(AppFonts.button())
            .foregroundStyle(AppTheme.textOnPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(AppFonts.button())
            .foregroundStyle(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
    }

    @ViewBuilder
    func loadingOverlay(_ isLoading: Bool, message: String = "") -> some View {
        overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                        if !message.isEmpty {
                            Text(message)
                                .font(AppFonts.subheadline())
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
                }
            }
        }
    }
}
