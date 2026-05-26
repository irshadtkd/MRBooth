//
//  VoterListView.swift
//  MRBooth
//

import SwiftUI

struct VoterListView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel = VoterListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            filterStrip
            countHeader
            if viewModel.displayedVoters.isEmpty {
                emptyState
            } else {
                voterList
            }
        }
        .background(AppTheme.background)
        .navigationTitle(AppStrings.voterList)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    coordinator.navigate(to: .filters)
                } label: {
                    Image(systemName: coordinator.filterCriteria.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .onAppear { refresh() }
        .onChange(of: coordinator.filterCriteria) { _, _ in refresh() }
        .onChange(of: viewModel.searchText) { _, _ in refresh() }
        .onChange(of: coordinator.services.voterRepository.voters) { _, _ in refresh() }
        .loadingOverlay(viewModel.isProcessing)
        .errorAlert(error: $viewModel.activeError)
        .confirmationDialog(
            AppStrings.deleteConfirmTitle,
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(AppStrings.delete, role: .destructive) {
                Task { await viewModel.deleteConfirmed(coordinator: coordinator) }
            }
            Button(AppStrings.cancel, role: .cancel) {}
        } message: {
            Text(AppStrings.deleteConfirmMessage)
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textSecondary)
            TextField(AppStrings.searchVoters, text: $viewModel.searchText)
                .font(AppFonts.body())
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(12)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
        .padding(.horizontal, AppTheme.paddingMedium)
        .padding(.top, AppTheme.paddingMedium)
    }

    private var filterStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppStrings.filterByVoting)
                .font(AppFonts.caption(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, AppTheme.paddingMedium)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VotingStatus.allCases) { status in
                        CompactFilterChipView(
                            title: status.displayName,
                            color: status.color,
                            isSelected: coordinator.filterCriteria.selectedVotingStatuses.contains(status)
                        ) {
                            viewModel.toggleVotingFilter(status, coordinator: coordinator)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.paddingMedium)
            }

            Text(AppStrings.filterByParty)
                .font(AppFonts.caption(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, AppTheme.paddingMedium)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PartyStatus.allCases) { party in
                        CompactFilterChipView(
                            title: party.displayName,
                            color: party.color,
                            isSelected: coordinator.filterCriteria.selectedParties.contains(party)
                        ) {
                            viewModel.togglePartyFilter(party, coordinator: coordinator)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.paddingMedium)
            }
        }
        .padding(.vertical, 12)
    }

    private var countHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: AppStrings.totalVoterCount, viewModel.totalCount))
                    .font(AppFonts.subheadline(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                if viewModel.hasAppliedCriteria {
                    Text(String(format: AppStrings.showingFilteredCount, viewModel.displayedCount))
                        .font(AppFonts.caption())
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
            if viewModel.hasAppliedCriteria {
                Button(AppStrings.clearFilters) {
                    viewModel.clearFilters(coordinator: coordinator)
                }
                .font(AppFonts.caption(.semibold))
                .foregroundStyle(AppTheme.primary)
            }
        }
        .padding(.horizontal, AppTheme.paddingMedium)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: viewModel.totalCount == 0 ? "person.crop.rectangle.stack" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            Text(viewModel.totalCount == 0 ? AppStrings.noVoters : AppStrings.noMatchingVoters)
                .font(AppFonts.headline())
            Text(viewModel.totalCount == 0 ? AppStrings.noVotersHint : AppStrings.noMatchingVotersHint)
                .font(AppFonts.subheadline())
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            if viewModel.hasAppliedCriteria {
                Button(AppStrings.clearFilters) {
                    viewModel.clearFilters(coordinator: coordinator)
                }
                .font(AppFonts.subheadline(.semibold))
                .foregroundStyle(AppTheme.primary)
                .padding(.top, 4)
            }
            Spacer()
        }
        .padding(.horizontal, AppTheme.paddingLarge)
    }

    private var voterList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.displayedVoters) { voter in
                    VoterCardView(
                        voter: voter,
                        onEdit: { coordinator.navigate(to: .editVoter(voter)) },
                        onDelete: { viewModel.confirmDelete(voter) },
                        onToggleVoted: {
                            Task { await viewModel.toggleVoted(voter, coordinator: coordinator) }
                        },
                        onPartyChange: { party in
                            Task { await viewModel.updateParty(voter, party: party, coordinator: coordinator) }
                        }
                    )
                }
            }
            .padding(AppTheme.paddingMedium)
        }
    }

    private func refresh() {
        viewModel.refresh(
            repository: coordinator.services.voterRepository,
            filters: coordinator.filterCriteria
        )
    }
}
