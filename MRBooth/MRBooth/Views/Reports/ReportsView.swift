//
//  ReportsView.swift
//  MRBooth
//

import SwiftUI

struct ReportsView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel = ReportsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                votingProgressCard
                partyDistributionCard
            }
            .padding(AppTheme.paddingMedium)
        }
        .background(AppTheme.background)
        .navigationTitle(AppStrings.reportsTitle)
        .onAppear { viewModel.refresh(repository: coordinator.services.voterRepository) }
        .onChange(of: coordinator.services.voterRepository.voters) { _, _ in
            viewModel.refresh(repository: coordinator.services.voterRepository)
        }
    }

    private var votingProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppStrings.votingProgress)
                .font(AppFonts.headline())
            HStack {
                VotingProgressRingView(stats: viewModel.stats)
                VStack(alignment: .leading, spacing: 12) {
                    reportRow(label: AppStrings.totalVoters, value: "\(viewModel.stats.total)")
                    reportRow(label: AppStrings.voted, value: "\(viewModel.stats.voted)", color: AppTheme.success)
                    reportRow(label: AppStrings.remaining, value: "\(viewModel.stats.remaining)", color: AppTheme.accent)
                }
                Spacer()
            }
        }
        .cardStyle()
    }

    private var partyDistributionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppStrings.partyDistribution)
                .font(AppFonts.headline())
            PartyBarChartView(items: viewModel.partyItems)
        }
        .cardStyle()
    }

    private func reportRow(label: String, value: String, color: Color = AppTheme.textPrimary) -> some View {
        HStack {
            Text(label)
                .font(AppFonts.subheadline())
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(AppFonts.headline())
                .foregroundStyle(color)
        }
    }
}
