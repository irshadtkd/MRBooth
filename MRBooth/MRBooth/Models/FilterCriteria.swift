//
//  FilterCriteria.swift
//  MRBooth
//

import Foundation

struct FilterCriteria: Codable, Equatable {
    var selectedParties: Set<PartyStatus> = []
    var selectedVotingStatuses: Set<VotingStatus> = []

    var isActive: Bool {
        !selectedParties.isEmpty || !selectedVotingStatuses.isEmpty
    }

    mutating func reset() {
        selectedParties = []
        selectedVotingStatuses = []
    }

    func matches(_ voter: Voter) -> Bool {
        if !selectedParties.isEmpty && !selectedParties.contains(voter.partyStatus) {
            return false
        }
        if !selectedVotingStatuses.isEmpty && !selectedVotingStatuses.contains(voter.votingStatus) {
            return false
        }
        return true
    }
}

struct DashboardStats: Equatable {
    var total: Int = 0
    var voted: Int = 0
    var remaining: Int { max(0, total - voted) }
}

struct PartyReportItem: Identifiable, Equatable {
    let id = UUID()
    let party: PartyStatus
    let count: Int
    let percentage: Double
}

struct ScanDraft: Identifiable, Equatable {
    let id: String
    var voter: Voter
    var isDuplicate: Bool
    var isSelected: Bool

    init(voter: Voter, isDuplicate: Bool, isSelected: Bool = true) {
        self.id = UUID().uuidString
        self.voter = voter
        self.isDuplicate = isDuplicate
        self.isSelected = isSelected
    }
}
