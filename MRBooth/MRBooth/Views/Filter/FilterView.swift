//
//  FilterView.swift
//  MRBooth
//

import SwiftUI

struct FilterView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel: FilterViewModel
    @Environment(\.dismiss) private var dismiss

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        _viewModel = StateObject(wrappedValue: FilterViewModel(criteria: coordinator.filterCriteria))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                partySection
                votingSection
                actions
            }
            .padding(AppTheme.paddingLarge)
        }
        .background(AppTheme.background)
        .navigationTitle(AppStrings.filterTitle)
    }

    private var partySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppStrings.partyStatus)
                .font(AppFonts.headline())
                .foregroundStyle(AppTheme.textPrimary)
            ForEach(PartyStatus.allCases) { party in
                FilterChipView(
                    title: party.displayName,
                    color: party.color,
                    isSelected: viewModel.draft.selectedParties.contains(party)
                ) {
                    viewModel.toggleParty(party)
                }
            }
        }
    }

    private var votingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppStrings.votingStatus)
                .font(AppFonts.headline())
                .foregroundStyle(AppTheme.textPrimary)
            ForEach(VotingStatus.allCases) { status in
                FilterChipView(
                    title: status.displayName,
                    color: status.color,
                    isSelected: viewModel.draft.selectedVotingStatuses.contains(status)
                ) {
                    viewModel.toggleVoting(status)
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                coordinator.saveFilters(viewModel.draft)
                dismiss()
            } label: {
                Text(AppStrings.applyFilters).primaryButtonStyle()
            }
            Button {
                viewModel.reset()
                coordinator.saveFilters(viewModel.draft)
            } label: {
                Text(AppStrings.resetFilters).secondaryButtonStyle()
            }
        }
    }
}
