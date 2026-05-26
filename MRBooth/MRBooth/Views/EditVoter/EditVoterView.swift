//
//  EditVoterView.swift
//  MRBooth
//

import SwiftUI

struct EditVoterView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel: EditVoterViewModel
    @Environment(\.dismiss) private var dismiss

    init(coordinator: AppCoordinator, voter: Voter) {
        self.coordinator = coordinator
        _viewModel = StateObject(wrappedValue: EditVoterViewModel(voter: voter))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MRBoothTextField(title: AppStrings.serialNumber, text: $viewModel.voter.serialNumber)
                MRBoothTextField(title: AppStrings.name, text: $viewModel.voter.name)
                MRBoothTextField(title: AppStrings.address, text: $viewModel.voter.address)
                MRBoothTextField(title: AppStrings.voterID, text: $viewModel.voter.voterID)
                MRBoothTextField(title: AppStrings.age, text: $viewModel.voter.age, isNumeric: true)
                partyPicker
                votingPicker
                Button {
                    Task {
                        await viewModel.save(coordinator: coordinator)
                        if viewModel.didSave { dismiss() }
                    }
                } label: {
                    Text(AppStrings.saveChanges).primaryButtonStyle()
                }
            }
            .padding(AppTheme.paddingLarge)
        }
        .background(AppTheme.background)
        .navigationTitle(AppStrings.editVoter)
        .loadingOverlay(viewModel.isSaving)
        .errorAlert(error: $viewModel.activeError)
    }

    private var partyPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(AppStrings.partyStatusLabel)
                .font(AppFonts.caption(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Picker(AppStrings.partyStatusLabel, selection: $viewModel.voter.partyStatus) {
                ForEach(PartyStatus.allCases) { party in
                    Text(party.displayName).tag(party)
                }
            }
            .pickerStyle(.segmented)
            .colorScheme(.light)
        }
    }

    private var votingPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(AppStrings.votingStatusLabel)
                .font(AppFonts.caption(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Picker(AppStrings.votingStatusLabel, selection: $viewModel.voter.votingStatus) {
                ForEach(VotingStatus.allCases) { status in
                    Text(status.displayName).tag(status)
                }
            }
            .pickerStyle(.segmented)
            .colorScheme(.light)
        }
    }
}
