//
//  GoogleSheetsService.swift
//  MRBooth
//

import Foundation

final class GoogleSheetsService: SheetsServiceProtocol, @unchecked Sendable {
    private let store: SessionStore

    init(store: SessionStore = .shared) {
        self.store = store
    }

    func findVoterSheet(folderID: String, accessToken: String) async throws -> String? {
        try await findSpreadsheet(
            named: VoterSheetConstants.spreadsheetName,
            in: folderID,
            accessToken: accessToken
        )
    }

    func linkVoterSheet(
        booth: BoothProfile,
        folderID: String,
        accessToken: String,
        choice: VoterSheetLinkChoice,
        existingSheetID: String?
    ) async throws -> String {
        _ = booth
        switch choice {
        case .reuseExisting:
            guard let sheetID = existingSheetID, !sheetID.isEmpty else {
                throw AppError.sheetOperationFailed("No existing sheet to reuse")
            }
            try await ensureInBoothFolder(fileID: sheetID, folderID: folderID, accessToken: accessToken)
            try await ensureHeaders(spreadsheetID: sheetID, accessToken: accessToken)
            _ = try await fetchVoters(sheetID: sheetID, accessToken: accessToken)
            return sheetID
        case .createNew:
            try await deleteVoterSheets(
                folderID: folderID,
                including: existingSheetID,
                accessToken: accessToken
            )
            return try await createNewVoterSheet(folderID: folderID, accessToken: accessToken)
        }
    }

    private func createNewVoterSheet(folderID: String, accessToken: String) async throws -> String {
        struct CreateRequest: Encodable {
            struct Properties: Encodable { let title: String }
            let properties: Properties
        }
        struct CreateResponse: Decodable { let spreadsheetId: String }

        let url = APIConstants.Sheets.createSpreadsheet()
        let body = CreateRequest(properties: .init(title: VoterSheetConstants.spreadsheetName))
        let created: CreateResponse = try await GoogleAPIClient.postJSON(url: url, body: body, accessToken: accessToken)

        try await moveFileToFolder(fileID: created.spreadsheetId, folderID: folderID, accessToken: accessToken)
        try await writeHeaders(spreadsheetID: created.spreadsheetId, accessToken: accessToken)
        store.saveLocalVoters([])
        return created.spreadsheetId
    }

    func fetchVoters(sheetID: String, accessToken: String) async throws -> [Voter] {
        let sheetTitle = try await GoogleSheetsAPI.firstSheetTitle(spreadsheetID: sheetID, accessToken: accessToken)
        let range = GoogleSheetsAPI.a1Range(sheetTitle: sheetTitle, cells: "A2:I")
        guard let url = GoogleSheetsAPI.valuesURL(spreadsheetID: sheetID, range: range) else {
            throw AppError.sheetOperationFailed("Invalid sheet range")
        }
        struct Response: Decodable { let values: [[String]]? }
        let response: Response = try await GoogleAPIClient.getJSON(url: url, accessToken: accessToken)
        let rows = response.values ?? []
        let voters = rows.enumerated().compactMap { index, row in
            Voter.fromSheetRow(row, rowIndex: index + 2)
        }.ensuringUniqueIDs()
        store.saveLocalVoters(voters)
        return voters
    }

    func appendVoters(_ voters: [Voter], sheetID: String, accessToken: String) async throws {
        for voter in voters {
            let existing = store.loadLocalVoters()
            let id = VoterIDParser.normalize(voter.voterID)
            if existing.contains(where: { VoterIDParser.normalize($0.voterID) == id && !id.isEmpty }) {
                throw AppError.duplicateVoter(id)
            }
        }

        let sheetTitle = try await GoogleSheetsAPI.firstSheetTitle(spreadsheetID: sheetID, accessToken: accessToken)
        let range = GoogleSheetsAPI.a1Range(sheetTitle: sheetTitle, cells: "A:I")
        guard let url = GoogleSheetsAPI.appendURL(spreadsheetID: sheetID, range: range) else {
            throw AppError.sheetOperationFailed("Invalid append URL")
        }

        let values = voters.map { $0.sheetRowValues() }
        try await GoogleAPIClient.postJSON(
            url: url,
            body: GoogleSheetsAPI.AppendBody(values: values),
            accessToken: accessToken
        )

        var local = store.loadLocalVoters()
        for voter in voters {
            let key = VoterIDParser.normalize(voter.voterID)
            if key.isEmpty || !local.contains(where: { VoterIDParser.normalize($0.voterID) == key }) {
                local.append(voter)
            }
        }
        store.saveLocalVoters(local)
    }

    func updateVoter(_ voter: Voter, sheetID: String, accessToken: String) async throws {
        var local = store.loadLocalVoters()
        guard let index = local.firstIndex(where: { $0.id == voter.id }) else {
            throw AppError.voterNotFound
        }
        let sheetTitle = try await GoogleSheetsAPI.firstSheetTitle(spreadsheetID: sheetID, accessToken: accessToken)
        let row = index + 2
        let range = GoogleSheetsAPI.a1Range(sheetTitle: sheetTitle, cells: "A\(row):I\(row)")
        guard let url = GoogleSheetsAPI.valuesURL(spreadsheetID: sheetID, range: range) else {
            throw AppError.sheetOperationFailed("Invalid update range")
        }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "valueInputOption", value: "USER_ENTERED")]
        guard let putURL = components?.url else {
            throw AppError.sheetOperationFailed("Invalid update URL")
        }

        try await GoogleAPIClient.putJSON(
            url: putURL,
            body: GoogleSheetsAPI.ValueUpdateBody(values: [voter.sheetRowValues()]),
            accessToken: accessToken
        )
        local[index] = voter
        store.saveLocalVoters(local)
    }

    func deleteVoter(_ voter: Voter, sheetID: String, accessToken: String) async throws {
        var local = store.loadLocalVoters()
        guard let index = local.firstIndex(where: { $0.id == voter.id }) else {
            throw AppError.voterNotFound
        }
        let row = index + 2
        let grid = try await GoogleSheetsAPI.firstSheetGrid(spreadsheetID: sheetID, accessToken: accessToken)
        try await deleteSheetRows(
            spreadsheetID: sheetID,
            sheetId: grid.sheetId,
            startIndex: row - 1,
            endIndex: row,
            accessToken: accessToken
        )
        local.remove(at: index)
        store.saveLocalVoters(local)
    }

    func clearAllVoters(sheetID: String, accessToken: String) async throws {
        let grid = try await GoogleSheetsAPI.firstSheetGrid(spreadsheetID: sheetID, accessToken: accessToken)
        let range = GoogleSheetsAPI.a1Range(sheetTitle: grid.title, cells: "A2:I")
        guard let url = GoogleSheetsAPI.valuesURL(spreadsheetID: sheetID, range: range) else {
            throw AppError.sheetOperationFailed("Invalid sheet range")
        }
        struct Response: Decodable { let values: [[String]]? }
        let response: Response = try await GoogleAPIClient.getJSON(url: url, accessToken: accessToken)
        let rowCount = response.values?.count ?? 0
        if rowCount > 0 {
            try await deleteSheetRows(
                spreadsheetID: sheetID,
                sheetId: grid.sheetId,
                startIndex: 1,
                endIndex: 1 + rowCount,
                accessToken: accessToken
            )
        }
        store.saveLocalVoters([])
    }

    private func deleteSheetRows(
        spreadsheetID: String,
        sheetId: Int,
        startIndex: Int,
        endIndex: Int,
        accessToken: String
    ) async throws {
        struct BatchUpdateBody: Encodable {
            let requests: [RequestItem]

            struct RequestItem: Encodable {
                let deleteDimension: DeleteDimensionPayload
            }

            struct DeleteDimensionPayload: Encodable {
                let range: DimensionRange
            }

            struct DimensionRange: Encodable {
                let sheetId: Int
                let dimension: String
                let startIndex: Int
                let endIndex: Int
            }
        }
        let url = APIConstants.Sheets.batchUpdate(spreadsheetID: spreadsheetID)
        let body = BatchUpdateBody(requests: [
            .init(deleteDimension: .init(range: .init(
                sheetId: sheetId,
                dimension: "ROWS",
                startIndex: startIndex,
                endIndex: endIndex
            )))
        ])
        try await GoogleAPIClient.postJSON(url: url, body: body, accessToken: accessToken)
    }

    // MARK: - Drive lookup

    private func findSpreadsheet(
        named name: String,
        in folderID: String,
        accessToken: String
    ) async throws -> String? {
        let inFolder = try await findSpreadsheetIDs(named: name, parentID: folderID, accessToken: accessToken)
        if let first = inFolder.first {
            return first
        }
        // Sheets created via the Sheets API start in Drive root; include orphans from failed moves.
        let inRoot = try await findSpreadsheetIDs(named: name, parentID: "root", accessToken: accessToken)
        return inRoot.first
    }

    private func findSpreadsheetIDs(
        named name: String,
        parentID: String,
        accessToken: String
    ) async throws -> [String] {
        let escapedName = name.replacingOccurrences(of: "'", with: "\\'")
        let query = """
        mimeType='application/vnd.google-apps.spreadsheet' \
        and name='\(escapedName)' \
        and trashed=false \
        and '\(parentID)' in parents
        """
        guard let url = APIConstants.Drive.searchFiles(
            query: query,
            fields: "files(id)",
            orderBy: "modifiedTime desc"
        ) else {
            throw AppError.sheetOperationFailed("Invalid Drive search URL")
        }
        struct Response: Decodable {
            struct File: Decodable { let id: String }
            let files: [File]
        }
        let response: Response = try await GoogleAPIClient.getJSON(url: url, accessToken: accessToken)
        return response.files.map(\.id)
    }

    private func deleteVoterSheets(
        folderID: String,
        including extraID: String?,
        accessToken: String
    ) async throws {
        let name = VoterSheetConstants.spreadsheetName
        var ids = Set(try await findSpreadsheetIDs(named: name, parentID: folderID, accessToken: accessToken))
        ids.formUnion(try await findSpreadsheetIDs(named: name, parentID: "root", accessToken: accessToken))
        if let extraID, !extraID.isEmpty {
            ids.insert(extraID)
        }
        for id in ids {
            try await deleteSpreadsheet(id: id, accessToken: accessToken)
        }
    }

    private func deleteSpreadsheet(id: String, accessToken: String) async throws {
        let url = APIConstants.Drive.file(id: id)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.networkUnavailable
        }
        guard http.statusCode == 204 || (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw AppError.sheetOperationFailed("Could not delete existing sheet: \(message)")
        }
    }

    private func ensureInBoothFolder(fileID: String, folderID: String, accessToken: String) async throws {
        let inFolder = try await findSpreadsheetIDs(
            named: VoterSheetConstants.spreadsheetName,
            parentID: folderID,
            accessToken: accessToken
        )
        guard !inFolder.contains(fileID) else { return }
        try await moveFileToFolder(fileID: fileID, folderID: folderID, accessToken: accessToken)
    }

    private func ensureHeaders(spreadsheetID: String, accessToken: String) async throws {
        let sheetTitle = try await GoogleSheetsAPI.firstSheetTitle(spreadsheetID: spreadsheetID, accessToken: accessToken)
        let range = GoogleSheetsAPI.a1Range(sheetTitle: sheetTitle, cells: "A1:I1")
        guard let url = GoogleSheetsAPI.valuesURL(spreadsheetID: spreadsheetID, range: range) else { return }
        struct Response: Decodable { let values: [[String]]? }
        let response: Response = try await GoogleAPIClient.getJSON(url: url, accessToken: accessToken)
        let firstCell = response.values?.first?.first?.trimmingCharacters(in: .whitespaces) ?? ""
        if firstCell.isEmpty {
            try await writeHeaders(spreadsheetID: spreadsheetID, sheetTitle: sheetTitle, accessToken: accessToken)
        }
    }

    private func writeHeaders(spreadsheetID: String, sheetTitle: String? = nil, accessToken: String) async throws {
        let title: String
        if let sheetTitle {
            title = sheetTitle
        } else {
            title = try await GoogleSheetsAPI.firstSheetTitle(spreadsheetID: spreadsheetID, accessToken: accessToken)
        }
        let range = GoogleSheetsAPI.a1Range(sheetTitle: title, cells: "A1:I1")
        let url = APIConstants.Sheets.valuesBatchUpdate(spreadsheetID: spreadsheetID)
        try await GoogleAPIClient.postJSON(
            url: url,
            body: GoogleSheetsAPI.BatchValueBody(data: .init(range: range, values: [Voter.sheetHeaders])),
            accessToken: accessToken
        )
    }

    private func moveFileToFolder(fileID: String, folderID: String, accessToken: String) async throws {
        guard let url = APIConstants.Drive.moveFile(
            id: fileID,
            addParents: folderID,
            removeParents: "root"
        ) else {
            throw AppError.driveSetupFailed("Could not move sheet into booth folder")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AppError.driveSetupFailed("Could not move sheet into booth folder")
        }
    }
}
