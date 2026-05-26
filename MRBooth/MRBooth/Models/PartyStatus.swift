//
//  PartyStatus.swift
//  MRBooth
//

import SwiftUI

enum PartyStatus: String, CaseIterable, Codable, Identifiable {
    case ldf = "LDF"
    case udf = "UDF"
    case other = "Other"
    case chance = "Chance / Maybe"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var color: Color {
        switch self {
        case .ldf: return AppTheme.ldfColor
        case .udf: return AppTheme.udfColor
        case .other: return AppTheme.otherColor
        case .chance: return AppTheme.chanceColor
        }
    }
}
