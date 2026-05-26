//
//  Voter.swift
//  MRBooth
//

import Foundation

struct Voter: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var serialNumber: String
    var name: String
    var address: String
    var voterID: String
    var age: String
    var partyStatus: PartyStatus
    var votingStatus: VotingStatus
    var createdAt: Date
    var updatedAt: Date

    var rowIndex: Int?

    init(
        id: String = UUID().uuidString,
        serialNumber: String = "",
        name: String = "",
        address: String = "",
        voterID: String = "",
        age: String = "",
        partyStatus: PartyStatus = .other,
        votingStatus: VotingStatus = .notVoted,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        rowIndex: Int? = nil
    ) {
        self.id = id
        self.serialNumber = serialNumber
        self.name = name
        self.address = address
        self.voterID = voterID
        self.age = age
        self.partyStatus = partyStatus
        self.votingStatus = votingStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.rowIndex = rowIndex
    }

    var missingFields: [String] {
        var missing: [String] = []
        if serialNumber.trimmingCharacters(in: .whitespaces).isEmpty { missing.append(AppStrings.serialNumber) }
        if name.trimmingCharacters(in: .whitespaces).isEmpty { missing.append(AppStrings.name) }
        if voterID.trimmingCharacters(in: .whitespaces).isEmpty { missing.append(AppStrings.voterID) }
        return missing
    }

    var hasValidationIssues: Bool { !missingFields.isEmpty }

    /// Column D — accepts "Voter ID" or "SEC ID No" (same data).
    static let sheetVoterIDHeader = "Voter ID / SEC ID No"

    static let sheetHeaders = [
        "Serial Number", "Name", "Address", sheetVoterIDHeader, "Age",
        "Party Status", "Voting Status", "Created Date", "Updated Date"
    ]

    func sheetRowValues() -> [String] {
        let formatter = ISO8601DateFormatter()
        return [
            serialNumber, name, address, voterID, age,
            partyStatus.rawValue, votingStatus.rawValue,
            formatter.string(from: createdAt),
            formatter.string(from: updatedAt)
        ]
    }

    static func fromSheetRow(_ row: [String], rowIndex: Int) -> Voter? {
        guard row.count >= 7 else { return nil }
        let formatter = ISO8601DateFormatter()
        let created = row.count > 7 ? formatter.date(from: row[7]) ?? Date() : Date()
        let updated = row.count > 8 ? formatter.date(from: row[8]) ?? Date() : Date()
        let rawID = cell(row, 3)
        let voterID = VoterIDParser.normalize(rawID)
        return Voter(
            id: UUID().uuidString,
            serialNumber: cell(row, 0),
            name: cell(row, 1),
            address: cell(row, 2),
            voterID: voterID,
            age: cell(row, 4),
            partyStatus: PartyStatus(rawValue: cell(row, 5)) ?? .other,
            votingStatus: VotingStatus(rawValue: cell(row, 6)) ?? .notVoted,
            createdAt: created,
            updatedAt: updated,
            rowIndex: rowIndex
        )
    }

    private static func cell(_ row: [String], _ index: Int) -> String {
        guard index >= 0, index < row.count else { return "" }
        return row[index]
    }
}

extension Array where Element == Voter {
    /// SwiftUI `ForEach` crashes if two voters share the same `id`.
    func ensuringUniqueIDs() -> [Voter] {
        var seen = Set<String>()
        return map { voter in
            var copy = voter
            if seen.contains(copy.id) {
                copy.id = UUID().uuidString
            }
            seen.insert(copy.id)
            return copy
        }
    }
}
