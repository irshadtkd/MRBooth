//
//  AIExtractedVoter.swift
//  MRBooth
//

import Foundation

struct AIExtractedVoter: Codable, Equatable {
    var serialNumber: String
    var epicNumber: String
    var name: String
    var address: String
    var sex: String
    var age: String

    enum CodingKeys: String, CodingKey {
        case serialNumber = "serial_number"
        case epicNumber = "epic_number"
        case name
        case address
        case sex
        case age
    }

    func toVoter() -> Voter {
        let voterID = VoterIDParser.normalize(epicNumber)
        return Voter(
            serialNumber: serialNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            voterID: voterID,
            age: Self.combinedAgeSex(age: age, sex: sex)
        )
    }

    var isEffectivelyEmpty: Bool {
        serialNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && epicNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func combinedAgeSex(age: String, sex: String) -> String {
        let a = age.trimmingCharacters(in: .whitespacesAndNewlines)
        let s = sex.trimmingCharacters(in: .whitespacesAndNewlines)
        if a.isEmpty { return s }
        if s.isEmpty { return a }
        if a.contains("/") || a.uppercased().hasSuffix(s.uppercased()) { return a }
        return "\(a)/\(s)"
    }
}
