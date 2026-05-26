//
//  DashboardView.swift
//  MRBooth
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                welcomeHeader
                statsRow
                menuSection
            }
            .padding(AppTheme.paddingMedium)
        }
        .background(AppTheme.background)
        .navigationTitle(AppStrings.dashboard)
        .onAppear { viewModel.refresh(from: coordinator.services.voterRepository) }
        .onChange(of: coordinator.services.voterRepository.voters) { _, _ in
            viewModel.refresh(from: coordinator.services.voterRepository)
        }
    }

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let session = coordinator.session {
                Text(session.displayName)
                    .font(AppFonts.headline())
                    .foregroundStyle(.white)
                Text(session.email)
                    .font(AppFonts.caption())
                    .foregroundStyle(.white.opacity(0.9))
            }
            if let booth = coordinator.session?.booth {
                Text("Booth \(booth.boothNumber)")
                    .font(AppFonts.title3())
                    .foregroundStyle(.white)
                Text(booth.displayLocation)
                    .font(AppFonts.caption())
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.paddingMedium)
        .background(AppTheme.primaryGradient)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCardView(title: AppStrings.totalVoters, value: "\(viewModel.stats.total)", color: AppTheme.primary, icon: "person.2.fill")
            StatCardView(title: AppStrings.voted, value: "\(viewModel.stats.voted)", color: AppTheme.success, icon: "checkmark.circle.fill")
            StatCardView(title: AppStrings.remaining, value: "\(viewModel.stats.remaining)", color: AppTheme.accent, icon: "hourglass")
        }
    }

    private var menuSection: some View {
        VStack(spacing: 12) {
            DashboardMenuCard(title: AppStrings.scanVoterList, icon: "doc.viewfinder", color: AppTheme.primary) {
                coordinator.navigate(to: .scan)
            }
            DashboardMenuCard(title: AppStrings.viewVoters, icon: "list.bullet.rectangle", color: AppTheme.secondary) {
                coordinator.navigate(to: .voterList)
            }
            DashboardMenuCard(title: AppStrings.filters, icon: "line.3.horizontal.decrease.circle", color: AppTheme.accent) {
                coordinator.navigate(to: .filters)
            }
            DashboardMenuCard(title: AppStrings.reports, icon: "chart.bar.fill", color: AppTheme.info) {
                coordinator.navigate(to: .reports)
            }
            DashboardMenuCard(title: AppStrings.settings, icon: "gearshape.fill", color: AppTheme.textSecondary) {
                coordinator.navigate(to: .settings)
            }
        }
    }
}
