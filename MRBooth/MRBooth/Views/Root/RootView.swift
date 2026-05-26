//
//  RootView.swift
//  MRBooth
//

import SwiftUI

struct RootView: View {
    @StateObject private var coordinator = AppCoordinator()

    var body: some View {
        Group {
            switch coordinator.phase {
            case .splash:
                SplashView()
            case .login:
                LoginView(coordinator: coordinator)
            case .registration:
                RegistrationView(coordinator: coordinator)
            case .main:
                mainNavigation
            }
        }
        .mrboothScreenStyle()
        .task {
            await coordinator.bootstrap()
        }
        .errorAlert(error: $coordinator.activeError)
    }

    @ViewBuilder
    private var mainNavigation: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            DashboardView(coordinator: coordinator)
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .scan:
            ScanView(coordinator: coordinator)
        case .voterList:
            VoterListView(coordinator: coordinator)
        case .filters:
            FilterView(coordinator: coordinator)
        case .editVoter(let voter):
            EditVoterView(coordinator: coordinator, voter: voter)
        case .reports:
            ReportsView(coordinator: coordinator)
        case .settings:
            SettingsView(coordinator: coordinator)
        }
    }
}

#Preview {
    RootView()
}
