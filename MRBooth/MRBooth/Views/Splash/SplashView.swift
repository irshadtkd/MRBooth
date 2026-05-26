//
//  SplashView.swift
//  MRBooth
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            AppTheme.splashGradient.ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.white)
                }
                VStack(spacing: 8) {
                    Text(AppStrings.appName)
                        .font(AppFonts.largeTitle())
                        .foregroundStyle(.white)
                    Text(AppStrings.appTagline)
                        .font(AppFonts.subheadline())
                        .foregroundStyle(.white.opacity(0.85))
                }
                ProgressView()
                    .tint(.white)
                    .padding(.top, 32)
                Text(AppStrings.splashLoading)
                    .font(AppFonts.caption())
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}

#Preview {
    SplashView()
}
