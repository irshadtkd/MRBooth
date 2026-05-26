//
//  LoginView.swift
//  MRBooth
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var isSigningIn = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                Spacer()
                content
                Spacer()
                footer
            }
        }
        .errorAlert(error: $coordinator.activeError)
        .loadingOverlay(isSigningIn)
        .onAppear {
            guard let session = coordinator.session, session.isLoggedIn else { return }
            if session.hasActiveRegistration {
                coordinator.phase = .main
            } else {
                coordinator.phase = .registration
            }
        }
    }

    private var header: some View {
        ZStack(alignment: .bottom) {
            AppTheme.primaryGradient
                .frame(height: 280)
                .ignoresSafeArea(edges: .top)
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                Text(AppStrings.appName)
                    .font(AppFonts.title())
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 40)
        }
    }

    private var content: some View {
        VStack(spacing: 20) {
            Text(AppStrings.loginTitle)
                .font(AppFonts.title2())
                .foregroundStyle(AppTheme.textPrimary)
            Text(AppStrings.loginSubtitle)
                .font(AppFonts.body())
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if coordinator.session?.isLoggedIn != true {
                Button {
                    Task {
                        isSigningIn = true
                        await coordinator.signIn()
                        isSigningIn = false
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "g.circle.fill")
                            .font(.title2)
                        Text(AppStrings.signInWithGoogle)
                    }
                    .primaryButtonStyle()
                }
                .padding(.horizontal, AppTheme.paddingLarge)
                .padding(.top, 8)
            }
        }
    }

    private var footer: some View {
        Text(AppStrings.loginFooter)
            .font(AppFonts.caption())
            .foregroundStyle(AppTheme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(AppTheme.paddingLarge)
    }
}

#Preview {
    LoginView(coordinator: AppCoordinator())
}
