//
//  VoterSheetLinkChoice.swift
//  MRBooth
//

import Foundation

enum VoterSheetLinkChoice {
    case reuseExisting
    case createNew
}

struct PendingSheetLinkContext: Equatable {
    var booth: BoothProfile
    var folderID: String
    var existingSheetID: String
}
