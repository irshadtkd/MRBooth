//
//  AuthServiceProtocol.swift
//  MRBooth
//

import Foundation

protocol AuthServiceProtocol: Sendable {
    /// Restores saved login (silent). Refreshes Google access token when possible.
    func restoreSession() async throws -> UserSession?
    func signIn() async throws -> UserSession
    /// Refreshes access token for API calls (Sheets/Drive sync).
    func refreshAccessToken() async throws -> String
    /// Requests Google Drive + Sheets OAuth scopes (booth registration).
    func requestDriveAndSheetsAccess() async throws -> String
    func signOut() async throws
}

protocol DriveServiceProtocol: Sendable {
    func createBoothFolder(booth: BoothProfile, accessToken: String) async throws -> String
}

protocol SheetsServiceProtocol: Sendable {
    func findVoterSheet(folderID: String, accessToken: String) async throws -> String?
    func linkVoterSheet(
        booth: BoothProfile,
        folderID: String,
        accessToken: String,
        choice: VoterSheetLinkChoice,
        existingSheetID: String?
    ) async throws -> String
    func fetchVoters(sheetID: String, accessToken: String) async throws -> [Voter]
    func appendVoters(_ voters: [Voter], sheetID: String, accessToken: String) async throws
    func updateVoter(_ voter: Voter, sheetID: String, accessToken: String) async throws
    func deleteVoter(_ voter: Voter, sheetID: String, accessToken: String) async throws
    func clearAllVoters(sheetID: String, accessToken: String) async throws
}

protocol OCRServiceProtocol: Sendable {
    func extractVoters(from imageData: Data) async throws -> [Voter]
    func extractVoters(from url: URL) async throws -> [Voter]
}

protocol GeminiAPIKeyProviding: Sendable {
    func loadGeminiAPIKey() -> String?
    func saveGeminiAPIKey(_ key: String)
}
