//
//  GoogleDriveService.swift
//  MRBooth
//

import Foundation

final class GoogleDriveService: DriveServiceProtocol, @unchecked Sendable {
    private let rootFolderName = "VoterManagement"

    func createBoothFolder(booth: BoothProfile, accessToken: String) async throws -> String {
        let rootID = try await findOrCreateFolder(named: rootFolderName, parentID: nil, accessToken: accessToken)
        return try await findOrCreateFolder(
            named: booth.boothName,
            parentID: rootID,
            accessToken: accessToken
        )
    }

    private func findOrCreateFolder(
        named name: String,
        parentID: String?,
        accessToken: String
    ) async throws -> String {
        if let existing = try await findFolder(named: name, parentID: parentID, accessToken: accessToken) {
            return existing
        }
        return try await createFolder(named: name, parentID: parentID, accessToken: accessToken)
    }

    private func findFolder(
        named name: String,
        parentID: String?,
        accessToken: String
    ) async throws -> String? {
        var query = "mimeType='application/vnd.google-apps.folder' and name='\(name)' and trashed=false"
        if let parentID {
            query += " and '\(parentID)' in parents"
        }
        guard let url = APIConstants.Drive.searchFiles(
            query: query,
            fields: "files(id,name)"
        ) else {
            throw AppError.driveSetupFailed("Invalid Drive search URL")
        }
        struct Response: Decodable { struct File: Decodable { let id: String }; let files: [File] }
        let response: Response = try await GoogleAPIClient.getJSON(url: url, accessToken: accessToken)
        return response.files.first?.id
    }

    private func createFolder(
        named name: String,
        parentID: String?,
        accessToken: String
    ) async throws -> String {
        struct Body: Encodable {
            let name: String
            let mimeType: String
            let parents: [String]?
        }
        struct File: Decodable { let id: String }
        let url = APIConstants.Drive.files()
        let body = Body(
            name: name,
            mimeType: "application/vnd.google-apps.folder",
            parents: parentID.map { [$0] }
        )
        let file: File = try await GoogleAPIClient.postJSON(url: url, body: body, accessToken: accessToken)
        return file.id
    }
}
