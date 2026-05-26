//
//  GoogleAPIClient.swift
//  MRBooth
//

import Foundation

enum GoogleAPIClient {
    static func postJSON<T: Encodable, R: Decodable>(
        url: URL,
        body: T,
        accessToken: String
    ) async throws -> R {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    static func getJSON<R: Decodable>(url: URL, accessToken: String) async throws -> R {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await perform(request)
    }

    static func putJSON<T: Encodable, R: Decodable>(
        url: URL,
        body: T,
        accessToken: String
    ) async throws -> R {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    static func putJSON<T: Encodable>(
        url: URL,
        body: T,
        accessToken: String
    ) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
    }

    static func postJSON<T: Encodable>(
        url: URL,
        body: T,
        accessToken: String
    ) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
    }

    private static func perform<R: Decodable>(_ request: URLRequest) async throws -> R {
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
        return try JSONDecoder().decode(R.self, from: data)
    }

    private static func validate(_ response: URLResponse, data: Data? = nil) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AppError.networkUnavailable
        }
        guard (200...299).contains(http.statusCode) else {
            let message = apiErrorMessage(from: data) ?? "HTTP \(http.statusCode)"
            throw AppError.sheetOperationFailed(message)
        }
    }

    private static func apiErrorMessage(from responseData: Data?) -> String? {
        guard let responseData else { return nil }
        if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }
        return String(data: responseData, encoding: .utf8)
    }
}
