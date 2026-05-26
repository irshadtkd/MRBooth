//
//  VoterIDParser.swift
//  MRBooth
//

import Foundation

/// Kerala voter lists use "Voter ID", "EPIC", or "New SEC ID No" (e.g. SEC012464328) for the same field.
enum VoterIDParser {
    /// EPIC format (e.g. ABC1234567).
    private static let epicPattern = #"[A-Z]{3}[0-9]{7}"#

    /// Kerala SEC electoral roll ID (e.g. SEC012464328).
    private static let secIDPattern = #"SEC[0-9]{9,12}"#

    /// Labelled SEC ID on OCR lines.
    private static let secLabelPattern =
        #"(?i)(?:new\s+)?SEC\s*ID\s*(?:No\.?|Number)?\s*[:.]?\s*(SEC[0-9]{9,12}|[A-Z]{3}[0-9]{7}|[A-Z0-9]{8,12})"#

    static let sheetHeaderAliases: Set<String> = [
        "voter id",
        "voterid",
        "voter id / sec id no",
        "sec id no",
        "sec id",
        "sec id number",
        "new sec id no",
        "new sec id no.",
        "epic",
        "epic no",
        "epic number"
    ]

    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    /// Returns the first voter / SEC ID found in text.
    static func extract(from text: String) -> String? {
        if let labelled = firstCapture(secLabelPattern, in: text) {
            return normalize(labelled)
        }
        if let range = text.range(of: secIDPattern, options: [.regularExpression, .caseInsensitive]) {
            return normalize(String(text[range]))
        }
        if let range = text.range(of: epicPattern, options: [.regularExpression, .caseInsensitive]) {
            return normalize(String(text[range]))
        }
        return nil
    }

    static func matchesSheetHeader(_ header: String) -> Bool {
        let key = header.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return sheetHeaderAliases.contains(key)
    }

    private static func firstCapture(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let capture = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[capture])
    }
}
