//
//  GoogleScopes.swift
//  MRBooth
//

import Foundation

enum GoogleScopes {
    static let driveFile = "https://www.googleapis.com/auth/drive.file"
    static let spreadsheets = "https://www.googleapis.com/auth/spreadsheets"

    /// Requested during booth registration (Drive folder + voter sheet).
    static let registration: [String] = [driveFile, spreadsheets]
}
