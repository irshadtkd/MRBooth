//
//  AppServices.swift
//  MRBooth
//

import Foundation

/// Central dependency container for the app.
@MainActor
final class AppServices: ObservableObject {
    static let shared = AppServices()

    let authService: AuthServiceProtocol
    let driveService: DriveServiceProtocol
    let sheetsService: SheetsServiceProtocol
    let ocrService: OCRServiceProtocol
    let sessionStore: SessionStore
    let voterRepository: VoterRepository

    init(
        authService: AuthServiceProtocol? = nil,
        driveService: DriveServiceProtocol? = nil,
        sheetsService: SheetsServiceProtocol? = nil,
        ocrService: OCRServiceProtocol = GeminiOCRService(),
        sessionStore: SessionStore = .shared
    ) {
        self.sessionStore = sessionStore
        self.authService = authService ?? FirebaseGoogleAuthService(store: sessionStore)
        self.driveService = driveService ?? GoogleDriveService()
        self.sheetsService = sheetsService ?? GoogleSheetsService(store: sessionStore)
        self.ocrService = ocrService
        self.voterRepository = VoterRepository(
            sheetsService: self.sheetsService,
            authService: self.authService,
            sessionStore: sessionStore
        )
    }
}

@MainActor
final class RegistrationService {
    private let authService: AuthServiceProtocol
    private let driveService: DriveServiceProtocol
    private let sheetsService: SheetsServiceProtocol
    private let sessionStore: SessionStore

    init(services: AppServices = .shared) {
        self.authService = services.authService
        self.driveService = services.driveService
        self.sheetsService = services.sheetsService
        self.sessionStore = services.sessionStore
    }

    /// Creates the booth Drive folder and detects an existing voter sheet. Does not link a sheet yet.
    func prepareBoothRegistration(
        profile: BoothProfile,
        session: inout UserSession
    ) async throws -> PendingSheetLinkContext? {
        if session.hasActiveRegistration {
            return nil
        }
        if session.isRegistered, session.booth?.sheetID != nil {
            throw AppError.alreadyRegistered
        }

        let token = try await authService.requestDriveAndSheetsAccess()
        session.accessToken = token
        sessionStore.saveSession(session)

        var booth = profile
        let folderID = try await driveService.createBoothFolder(booth: booth, accessToken: token)
        booth.driveFolderID = folderID

        if let existingSheetID = try await sheetsService.findVoterSheet(
            folderID: folderID,
            accessToken: token
        ) {
            return PendingSheetLinkContext(
                booth: booth,
                folderID: folderID,
                existingSheetID: existingSheetID
            )
        }

        try await completeSheetLink(
            booth: booth,
            session: &session,
            folderID: folderID,
            choice: .createNew,
            existingSheetID: nil,
            accessToken: token
        )
        return nil
    }

    func completeSheetLink(
        booth: BoothProfile,
        session: inout UserSession,
        folderID: String,
        choice: VoterSheetLinkChoice,
        existingSheetID: String?,
        accessToken: String? = nil
    ) async throws {
        if session.hasActiveRegistration {
            return
        }

        let token: String
        if let accessToken, !accessToken.isEmpty {
            token = accessToken
        } else {
            token = try await authService.requestDriveAndSheetsAccess()
            session.accessToken = token
        }

        var booth = booth
        booth.driveFolderID = folderID
        let sheetID = try await sheetsService.linkVoterSheet(
            booth: booth,
            folderID: folderID,
            accessToken: token,
            choice: choice,
            existingSheetID: existingSheetID
        )
        booth.sheetID = sheetID

        session.isRegistered = true
        session.hasGoogleDriveAccess = true
        session.booth = booth
        sessionStore.saveSession(session)
    }
}
