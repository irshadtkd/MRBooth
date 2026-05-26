//
//  FilterViewModel.swift
//  MRBooth
//

import Foundation

@MainActor
final class FilterViewModel: ObservableObject {
    @Published var draft: FilterCriteria

    init(criteria: FilterCriteria) {
        self.draft = criteria
    }

    func toggleParty(_ party: PartyStatus) {
        if draft.selectedParties.contains(party) {
            draft.selectedParties.remove(party)
        } else {
            draft.selectedParties.insert(party)
        }
    }

    func toggleVoting(_ status: VotingStatus) {
        if draft.selectedVotingStatuses.contains(status) {
            draft.selectedVotingStatuses.remove(status)
        } else {
            draft.selectedVotingStatuses.insert(status)
        }
    }

    func reset() {
        draft.reset()
    }
}
