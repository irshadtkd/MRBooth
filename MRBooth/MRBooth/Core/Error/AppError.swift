//
//  AppError.swift
//  MRBooth
//

import Foundation

enum AppError: LocalizedError, Equatable {
    case notAuthenticated
    case registrationRequired
    case alreadyRegistered
    case networkUnavailable
    case googleServiceUnavailable
    case driveSetupFailed(String)
    case sheetOperationFailed(String)
    case ocrFailed(String)
    case validationFailed(String)
    case duplicateVoter(String)
    case voterNotFound
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Your session could not be restored. Log out from Settings, then sign in again."
        case .registrationRequired:
            return "Complete booth registration before using the app."
        case .alreadyRegistered:
            return "This account is already registered to a booth."
        case .networkUnavailable:
            return AppStrings.offlineMessage
        case .googleServiceUnavailable:
            return "Google services are not configured. Add Google Sign-In SDK and OAuth client ID."
        case .driveSetupFailed(let detail):
            return "Failed to create Drive folder: \(detail)"
        case .sheetOperationFailed(let detail):
            return "Sheet sync failed: \(detail)"
        case .ocrFailed(let detail):
            return "AI extraction failed: \(detail)"
        case .validationFailed(let detail):
            return detail
        case .duplicateVoter(let id):
            return "\(AppStrings.duplicateVoter): \(id)"
        case .voterNotFound:
            return "Voter record not found."
        case .unknown(let detail):
            return detail
        }
    }
}
