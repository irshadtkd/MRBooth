//
//  AppTheme.swift
//  MRBooth
//

import SwiftUI

enum AppTheme {
    // MARK: - Brand
    static let primary = Color(red: 0.10, green: 0.35, blue: 0.72)
    static let primaryDark = Color(red: 0.05, green: 0.22, blue: 0.45)
    static let accent = Color(red: 0.95, green: 0.55, blue: 0.12)
    static let secondary = Color(red: 0.18, green: 0.55, blue: 0.38)

    // MARK: - Surfaces
    static let background = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let cardBackground = Color.white
    static let elevatedBackground = Color(red: 0.99, green: 0.99, blue: 1.0)
    /// Input fields — light gray surface with dark text.
    static let fieldBackground = Color(red: 0.94, green: 0.95, blue: 0.97)

    // MARK: - Text
    static let textPrimary = Color.black
    static let textSecondary = Color(red: 0.38, green: 0.42, blue: 0.50)
    static let textOnPrimary = Color.white

    // MARK: - Status
    static let success = Color(red: 0.16, green: 0.62, blue: 0.38)
    static let warning = Color(red: 0.92, green: 0.58, blue: 0.10)
    static let error = Color(red: 0.85, green: 0.22, blue: 0.22)
    static let info = Color(red: 0.20, green: 0.45, blue: 0.85)

    // MARK: - Party colors
    static let ldfColor = Color(red: 0.78, green: 0.12, blue: 0.14)
    static let udfColor = Color(red: 0.12, green: 0.35, blue: 0.78)
    static let otherColor = Color(red: 0.45, green: 0.45, blue: 0.48)
    static let chanceColor = Color(red: 0.55, green: 0.35, blue: 0.75)

    // MARK: - Voting
    static let votedColor = success
    static let notVotedColor = Color(red: 0.55, green: 0.58, blue: 0.62)

    // MARK: - Layout
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 24
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let shadowRadius: CGFloat = 8
    static let shadowOpacity: Double = 0.08

    // MARK: - Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var splashGradient: LinearGradient {
        LinearGradient(
            colors: [primaryDark, primary],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
