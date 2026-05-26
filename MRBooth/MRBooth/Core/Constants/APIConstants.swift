//
//  APIConstants.swift
//  MRBooth
//
//  Central place for API URLs, keys, and related constants.
//  Update values here only — do not hardcode them in service classes.
//

import Foundation

enum APIConstants {
    // MARK: - API keys

    enum Keys {
        static let geminiAPIKeyUserDefaults = "mrbooth.gemini.apiKey"
        static let geminiAPIKeyQueryParameter = "key"
    }

    // MARK: - Base URLs

    enum BaseURL {
        static let oauth2Google = "https://oauth2.googleapis.com"
        static let sheetsGoogleHost = "sheets.googleapis.com"
        static let sheetsGoogle = "https://\(sheetsGoogleHost)"
        static let driveGoogle = "https://www.googleapis.com/drive/v3"
        static let generativeLanguage = "https://generativelanguage.googleapis.com"
    }

    // MARK: - Gemini

    enum Gemini {
        static let modelPath = "v1beta/models/gemini-2.5-flash:generateContent"

        static func generateContentURL(apiKey: String) -> URL? {
            var components = URLComponents(string: "\(BaseURL.generativeLanguage)/\(modelPath)")
            components?.queryItems = [
                URLQueryItem(name: Keys.geminiAPIKeyQueryParameter, value: apiKey)
            ]
            return components?.url
        }
    }

    // MARK: - Google OAuth

    enum OAuth {
        static var tokenURL: URL {
            URL(string: "\(BaseURL.oauth2Google)/token")!
        }
    }

    // MARK: - Google Sheets

    enum Sheets {
        static func createSpreadsheet() -> URL {
            URL(string: "\(BaseURL.sheetsGoogle)/v4/spreadsheets")!
        }

        static func batchUpdate(spreadsheetID: String) -> URL {
            URL(string: "\(BaseURL.sheetsGoogle)/v4/spreadsheets/\(spreadsheetID):batchUpdate")!
        }

        static func valuesBatchUpdate(spreadsheetID: String) -> URL {
            URL(string: "\(BaseURL.sheetsGoogle)/v4/spreadsheets/\(spreadsheetID)/values:batchUpdate")!
        }

        static func metadata(spreadsheetID: String) -> URL {
            URL(string: "\(BaseURL.sheetsGoogle)/v4/spreadsheets/\(spreadsheetID)?fields=sheets.properties(title,sheetId)")!
        }
    }

    // MARK: - Google Drive

    enum Drive {
        static func files() -> URL {
            URL(string: "\(BaseURL.driveGoogle)/files")!
        }

        static func file(id: String) -> URL {
            URL(string: "\(BaseURL.driveGoogle)/files/\(id)")!
        }

        static func searchFiles(
            query: String,
            fields: String,
            orderBy: String? = nil
        ) -> URL? {
            var components = URLComponents(string: "\(BaseURL.driveGoogle)/files")
            var queryItems = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "spaces", value: "drive"),
                URLQueryItem(name: "fields", value: fields)
            ]
            if let orderBy {
                queryItems.append(URLQueryItem(name: "orderBy", value: orderBy))
            }
            components?.queryItems = queryItems
            return components?.url
        }

        static func moveFile(id: String, addParents: String, removeParents: String) -> URL? {
            var components = URLComponents(string: "\(BaseURL.driveGoogle)/files/\(id)")
            components?.queryItems = [
                URLQueryItem(name: "addParents", value: addParents),
                URLQueryItem(name: "removeParents", value: removeParents)
            ]
            return components?.url
        }
    }
}
