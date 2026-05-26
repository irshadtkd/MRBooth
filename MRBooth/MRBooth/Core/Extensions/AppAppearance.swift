//
//  AppAppearance.swift
//  MRBooth
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum AppAppearance {
    static func configure() {
        #if canImport(UIKit)
        let titleColor = UIColor(AppTheme.textPrimary)
        let background = UIColor(AppTheme.background)

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = background
        navAppearance.titleTextAttributes = [.foregroundColor: titleColor]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor]

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = navAppearance
        navBar.scrollEdgeAppearance = navAppearance
        navBar.compactAppearance = navAppearance
        navBar.tintColor = UIColor(AppTheme.primary)

        UITextField.appearance().textColor = titleColor

        let segment = UISegmentedControl.appearance()
        segment.setTitleTextAttributes([.foregroundColor: titleColor], for: .normal)
        segment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segment.selectedSegmentTintColor = UIColor(AppTheme.primary)
        segment.backgroundColor = UIColor(AppTheme.fieldBackground)
        #endif
    }
}

struct MRBoothScreenStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.light)
            .background(AppTheme.background)
            .foregroundStyle(AppTheme.textPrimary)
            #if os(iOS)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(AppTheme.primary)
            #endif
    }
}

extension View {
    func mrboothScreenStyle() -> some View {
        modifier(MRBoothScreenStyle())
    }
}
