//
//  GoogleSheetsAPI.swift
//  MRBooth
//

import Foundation

enum GoogleSheetsAPI {
    /// Google Sheets A1 ranges must keep `:` and `!` unencoded in the URL path.
    private static let rangeURLAllowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!:'.-_")

    struct AppendBody: Encodable {
        let values: [[String]]
    }

    struct ValueUpdateBody: Encodable {
        let values: [[String]]
    }

    struct BatchValueBody: Encodable {
        struct ValueRange: Encodable {
            let range: String
            let values: [[String]]
        }

        let valueInputOption = "USER_ENTERED"
        let data: ValueRange
    }

    static func a1Range(sheetTitle: String, cells: String) -> String {
        let escaped = sheetTitle.contains(" ")
            ? "'\(sheetTitle.replacingOccurrences(of: "'", with: "''"))'"
            : sheetTitle
        return "\(escaped)!\(cells)"
    }

    static func appendURL(spreadsheetID: String, range: String) -> URL? {
        let encodedRange = encodeRangeForURL(range)
        var components = URLComponents()
        components.scheme = "https"
        components.host = APIConstants.BaseURL.sheetsGoogleHost
        components.percentEncodedPath = "/v4/spreadsheets/\(spreadsheetID)/values/\(encodedRange):append"
        components.queryItems = [
            URLQueryItem(name: "valueInputOption", value: "USER_ENTERED"),
            URLQueryItem(name: "insertDataOption", value: "INSERT_ROWS")
        ]
        return components.url
    }

    static func valuesURL(spreadsheetID: String, range: String) -> URL? {
        let encodedRange = encodeRangeForURL(range)
        var components = URLComponents()
        components.scheme = "https"
        components.host = APIConstants.BaseURL.sheetsGoogleHost
        components.percentEncodedPath = "/v4/spreadsheets/\(spreadsheetID)/values/\(encodedRange)"
        return components.url
    }

    private static func encodeRangeForURL(_ range: String) -> String {
        range.addingPercentEncoding(withAllowedCharacters: rangeURLAllowed) ?? range
    }

    struct SheetGrid: Sendable {
        let title: String
        let sheetId: Int
    }

    static func firstSheetTitle(spreadsheetID: String, accessToken: String) async throws -> String {
        try await firstSheetGrid(spreadsheetID: spreadsheetID, accessToken: accessToken).title
    }

    static func firstSheetGrid(spreadsheetID: String, accessToken: String) async throws -> SheetGrid {
        let url = APIConstants.Sheets.metadata(spreadsheetID: spreadsheetID)
        struct Response: Decodable {
            struct Sheet: Decodable {
                struct Properties: Decodable {
                    let title: String
                    let sheetId: Int
                }
                let properties: Properties
            }
            let sheets: [Sheet]
        }
        let response: Response = try await GoogleAPIClient.getJSON(url: url, accessToken: accessToken)
        guard let sheet = response.sheets.first else {
            return SheetGrid(title: "Sheet1", sheetId: 0)
        }
        return SheetGrid(title: sheet.properties.title, sheetId: sheet.properties.sheetId)
    }
}
