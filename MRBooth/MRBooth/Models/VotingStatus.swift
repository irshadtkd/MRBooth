//
//  VotingStatus.swift
//  MRBooth
//

import SwiftUI

enum VotingStatus: String, CaseIterable, Codable, Identifiable {
    case voted = "Voted"
    case notVoted = "Not Voted"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var color: Color {
        switch self {
        case .voted: return AppTheme.votedColor
        case .notVoted: return AppTheme.notVotedColor
        }
    }
}
