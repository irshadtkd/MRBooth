//
//  GeminiAPIClient.swift
//  MRBooth
//

import Foundation

enum GeminiVoterExtractionPrompt {
    static let text = """
    You are an intelligent OCR extraction system.
    Analyze this voter list image carefully.
    Extract the following fields for every voter:
    1. Serial Number
    2. EPIC Number / Voter ID
    3. Name
    4. Address
    5. Sex
    6. Age
    Rules:
    - Return ONLY valid JSON array
    - Do not include explanations
    - Ignore headers/footers
    - Ignore page numbers
    - If a field is missing return empty string
    - Preserve original language text
    - Detect multiple voter rows correctly

    JSON Format:

    [
     {
       "serial_number":"",
       "epic_number":"",
       "name":"",
       "address":"",
       "sex":"",
       "age":""
     }
    ]
    """
}

final class GeminiAPIClient: @unchecked Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func extractVoters(fromJPEGBase64 base64: String, apiKey: String) async throws -> [AIExtractedVoter] {
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(parts: [
                    GeminiPart(text: GeminiVoterExtractionPrompt.text, inlineData: nil),
                    GeminiPart(
                        text: nil,
                        inlineData: GeminiInlineData(mimeType: "image/jpeg", data: base64)
                    )
                ])
            ]
        )

        guard let url = APIConstants.Gemini.generateContentURL(apiKey: apiKey) else {
            throw AppError.ocrFailed("Invalid Gemini API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let detail = Self.errorDetail(from: data) ?? "HTTP \(http.statusCode)"
            throw AppError.ocrFailed(detail)
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        if let apiError = geminiResponse.error {
            throw AppError.ocrFailed(apiError.message ?? apiError.status ?? "Gemini API error")
        }

        guard let text = geminiResponse.candidates?
            .first?
            .content?
            .parts?
            .compactMap(\.text)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty else {
            throw AppError.ocrFailed("Empty response from Gemini")
        }

        return try Self.parseVotersJSON(from: text)
    }

    static func parseVotersJSON(from text: String) throws -> [AIExtractedVoter] {
        let cleaned = stripMarkdownCodeFence(text)
        guard let jsonData = cleaned.data(using: .utf8) else {
            throw AppError.ocrFailed("Invalid JSON encoding")
        }
        do {
            return try JSONDecoder().decode([AIExtractedVoter].self, from: jsonData)
        } catch {
            throw AppError.ocrFailed("Could not parse voter JSON: \(error.localizedDescription)")
        }
    }

    private static func stripMarkdownCodeFence(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            result = result
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```JSON", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let start = result.firstIndex(of: "["),
           let end = result.lastIndex(of: "]") {
            result = String(result[start...end])
        }
        return result
    }

    private static func errorDetail(from data: Data) -> String? {
        if let decoded = try? JSONDecoder().decode(GeminiResponse.self, from: data),
           let message = decoded.error?.message {
            return message
        }
        return String(data: data, encoding: .utf8)
    }
}
