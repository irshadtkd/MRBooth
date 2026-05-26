//
//  SessionManager.swift
//  MRBooth
//

import Foundation

/// Keeps coordinator session in sync with auth + refreshed Google tokens.
@MainActor
enum SessionManager {
    static func prepareForAPI(
        authService: AuthServiceProtocol,
        sessionStore: SessionStore,
        session: inout UserSession?
    ) async throws {
        if var restored = try await authService.restoreSession() {
            if restored.hasActiveRegistration && restored.hasGoogleDriveAccess {
                let token = try await authService.refreshAccessToken()
                restored.accessToken = token
            }
            sessionStore.saveSession(restored)
            session = restored
            return
        }

        guard var current = session ?? sessionStore.loadSession(), current.isLoggedIn else {
            throw AppError.notAuthenticated
        }

        if current.hasActiveRegistration && current.hasGoogleDriveAccess {
            let token = try await authService.refreshAccessToken()
            current.accessToken = token
            sessionStore.saveSession(current)
        }
        session = current
    }
}
