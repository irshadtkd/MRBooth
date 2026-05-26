//
//  ElectionLevel.swift
//  MRBooth
//

import Foundation

enum ElectionLevel: String, Codable, CaseIterable, Identifiable {
    case lokSabha = "Lok Sabha"
    case assembly = "Assembly"
    case localBody = "Local Body"

    var id: String { rawValue }
}

enum LocalBodyKind: String, Codable, CaseIterable, Identifiable {
    case gramaPanchayat = "Grama Panchayat"
    case corporation = "Corporation"
    case municipality = "Municipality"

    var id: String { rawValue }
}
