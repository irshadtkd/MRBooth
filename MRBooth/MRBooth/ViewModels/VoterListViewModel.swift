//
//  VoterListViewModel.swift
//  MRBooth
//

import Foundation

@MainActor
final class VoterListViewModel: ObservableObject, ErrorPresenting {
    @Published var searchText = ""
    @Published var displayedVoters: [Voter] = []
    @Published var totalCount = 0
    @Published private(set) var filtersActive = false
    @Published var activeError: AppError?
    @Published var voterToDelete: Voter?
    @Published var showDeleteConfirmation = false
    @Published var isProcessing = false

    var isFiltering: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func refresh(repository: VoterRepository, filters: FilterCriteria) {
        totalCount = repository.voters.count
        displayedVoters = repository.filtered(filters, search: searchText)
        filtersActive = filters.isActive || isFiltering
    }

    var hasAppliedCriteria: Bool { filtersActive }

    var displayedCount: Int { displayedVoters.count }

    func togglePartyFilter(_ party: PartyStatus, coordinator: AppCoordinator) {
        var criteria = coordinator.filterCriteria
        if criteria.selectedParties.contains(party) {
            criteria.selectedParties.remove(party)
        } else {
            criteria.selectedParties.insert(party)
        }
        coordinator.saveFilters(criteria)
        refresh(repository: coordinator.services.voterRepository, filters: criteria)
    }

    func toggleVotingFilter(_ status: VotingStatus, coordinator: AppCoordinator) {
        var criteria = coordinator.filterCriteria
        if criteria.selectedVotingStatuses.contains(status) {
            criteria.selectedVotingStatuses.remove(status)
        } else {
            criteria.selectedVotingStatuses.insert(status)
        }
        coordinator.saveFilters(criteria)
        refresh(repository: coordinator.services.voterRepository, filters: criteria)
    }

    func clearFilters(coordinator: AppCoordinator) {
        searchText = ""
        var criteria = coordinator.filterCriteria
        criteria.reset()
        coordinator.saveFilters(criteria)
        refresh(repository: coordinator.services.voterRepository, filters: criteria)
    }

    func confirmDelete(_ voter: Voter) {
        voterToDelete = voter
        showDeleteConfirmation = true
    }

    func deleteConfirmed(coordinator: AppCoordinator) async {
        guard let voter = voterToDelete, let session = coordinator.session else { return }
        isProcessing = true
        defer {
            isProcessing = false
            voterToDelete = nil
            showDeleteConfirmation = false
        }
        do {
            try await coordinator.services.voterRepository.delete(voter, session: session)
            refresh(repository: coordinator.services.voterRepository, filters: coordinator.filterCriteria)
        } catch {
            handle(error)
        }
    }

    func toggleVoted(_ voter: Voter, coordinator: AppCoordinator) async {
        guard let session = coordinator.session else { return }
        var updated = voter
        updated.votingStatus = voter.votingStatus == .voted ? .notVoted : .voted
        updated.updatedAt = Date()
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await coordinator.services.voterRepository.update(updated, session: session)
            refresh(repository: coordinator.services.voterRepository, filters: coordinator.filterCriteria)
        } catch {
            handle(error)
        }
    }

    func updateParty(_ voter: Voter, party: PartyStatus, coordinator: AppCoordinator) async {
        guard let session = coordinator.session else { return }
        var updated = voter
        updated.partyStatus = party
        updated.updatedAt = Date()
        do {
            try await coordinator.services.voterRepository.update(updated, session: session)
            refresh(repository: coordinator.services.voterRepository, filters: coordinator.filterCriteria)
        } catch {
            handle(error)
        }
    }
}
