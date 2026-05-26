//
//  VoterCardView.swift
//  MRBooth
//

import SwiftUI

struct VoterCardView: View {
    let voter: Voter
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onToggleVoted: () -> Void
    var onPartyChange: (PartyStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("#\(voter.serialNumber)")
                            .font(AppFonts.caption(.bold))
                            .foregroundStyle(AppTheme.primary)
                        if voter.hasValidationIssues {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.warning)
                        }
                    }
                    Text(voter.name)
                        .font(AppFonts.headline())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(voter.voterID.isEmpty ? "No ID" : voter.voterID)
                        .font(AppFonts.caption())
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                votingBadge
            }

            if !voter.address.isEmpty {
                Label(voter.address, systemImage: "mappin.and.ellipse")
                    .font(AppFonts.caption())
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }

            HStack {
                Label("Age \(voter.age.isEmpty ? "—" : voter.age)", systemImage: "person")
                    .font(AppFonts.caption())
                Spacer()
                partyMenu
            }

            HStack(spacing: 12) {
                Button(action: onToggleVoted) {
                    Label(
                        voter.votingStatus == .voted ? "Voted" : AppStrings.markVoted,
                        systemImage: voter.votingStatus == .voted ? "checkmark.circle.fill" : "circle"
                    )
                    .font(AppFonts.caption(.semibold))
                    .foregroundStyle(voter.votingStatus.color)
                }
                Spacer()
                Button(AppStrings.editVoter, action: onEdit)
                    .font(AppFonts.caption(.semibold))
                    .foregroundStyle(AppTheme.primary)
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(AppFonts.caption())
                }
            }
        }
        .padding(AppTheme.paddingMedium)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
        .shadow(color: .black.opacity(AppTheme.shadowOpacity), radius: 4, y: 2)
    }

    private var votingBadge: some View {
        Text(voter.votingStatus.displayName)
            .font(AppFonts.caption2(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(voter.votingStatus.color.opacity(0.15))
            .foregroundStyle(voter.votingStatus.color)
            .clipShape(Capsule())
    }

    private var partyMenu: some View {
        Menu {
            ForEach(PartyStatus.allCases) { party in
                Button(party.displayName) { onPartyChange(party) }
            }
        } label: {
            HStack(spacing: 4) {
                Circle().fill(voter.partyStatus.color).frame(width: 8, height: 8)
                Text(voter.partyStatus.displayName)
                    .font(AppFonts.caption(.semibold))
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(voter.partyStatus.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(voter.partyStatus.color.opacity(0.12))
            .clipShape(Capsule())
        }
    }
}
