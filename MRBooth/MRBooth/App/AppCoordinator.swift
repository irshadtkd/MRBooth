//
//  AppCoordinator.swift
//  MRBooth
//

import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject, ErrorPresenting {
    @Published var phase: AppPhase = .splash
    @Published var session: UserSession?
    @Published var navigationPath = NavigationPath()
    @Published var filterCriteria: FilterCriteria
    @Published var activeError: AppError?

    let services: AppServices
    private let registrationService: RegistrationService

    init(services: AppServices = .shared) {
        self.services = services
        self.registrationService = RegistrationService(services: services)
        self.filterCriteria = services.sessionStore.loadFilters()
    }

    func bootstrap() async {
        phase = .splash
        do {
            if let restored = try await services.authService.restoreSession() {
                session = restored
                services.voterRepository.loadCached()
                applyPhase(for: restored)

                if restored.hasActiveRegistration {
                    await syncInBackground()
                }
            } else {
                phase = .login
            }
        } catch {
            if let saved = services.sessionStore.loadSession(), saved.isLoggedIn {
                session = saved
                services.voterRepository.loadCached()
                applyPhase(for: saved)
                if saved.hasActiveRegistration {
                    await syncInBackground()
                }
            } else {
                phase = .login
            }
        }
    }

    func signIn() async {
        if let current = session, current.isLoggedIn {
            applyPhase(for: current)
            if current.hasActiveRegistration {
                await syncInBackground()
            }
            return
        }
        if let saved = services.sessionStore.loadSession(), saved.isLoggedIn {
            session = saved
            services.sessionStore.saveSession(saved)
            applyPhase(for: saved)
            if saved.hasActiveRegistration {
                await syncInBackground()
            }
            return
        }

        do {
            let newSession = try await services.authService.signIn()
            session = newSession
            services.sessionStore.saveSession(newSession)
            applyPhase(for: newSession)
            if newSession.hasActiveRegistration {
                try await refreshSessionAndSync()
            }
        } catch {
            handle(error)
        }
    }

    func registerBooth(draft: RegistrationDraft) async -> PendingSheetLinkContext? {
        guard var current = session else {
            present(.notAuthenticated)
            return nil
        }
        if current.hasActiveRegistration {
            present(.alreadyRegistered)
            applyPhase(for: current)
            return nil
        }
        services.sessionStore.saveRegistrationDraft(draft)

        var profile = draft.toBoothProfile(userEmail: current.email)
        profile.registeredAt = Date()
        do {
            let pending = try await registrationService.prepareBoothRegistration(
                profile: profile,
                session: &current
            )
            session = current
            services.sessionStore.saveSession(current)
            if pending == nil {
                try await finishRegistration(session: &current)
            }
            return pending
        } catch {
            handle(error)
            return nil
        }
    }

    func completeBoothRegistration(
        choice: VoterSheetLinkChoice,
        pending: PendingSheetLinkContext
    ) async {
        guard var current = session else {
            present(.notAuthenticated)
            return
        }
        if current.hasActiveRegistration {
            present(.alreadyRegistered)
            applyPhase(for: current)
            return
        }
        do {
            try await registrationService.completeSheetLink(
                booth: pending.booth,
                session: &current,
                folderID: pending.folderID,
                choice: choice,
                existingSheetID: pending.existingSheetID,
                accessToken: current.accessToken
            )
            try await finishRegistration(session: &current)
        } catch {
            handle(error)
        }
    }

    private func finishRegistration(session: inout UserSession) async throws {
        session.hasGoogleDriveAccess = true
        session.lastLoginAt = Date()
        self.session = session
        services.sessionStore.saveSession(session)
        services.sessionStore.clearRegistrationDraft()
        try await refreshSessionAndSync()
        phase = .main
    }

    func signOut() async {
        do {
            try await services.authService.signOut()
            session = nil
            navigationPath = NavigationPath()
            phase = .login
        } catch {
            handle(error)
        }
    }

    func syncData() async {
        do {
            try await refreshSessionAndSync()
        } catch {
            handle(error)
        }
    }

    func clearAllVoterData() async {
        guard let current = session, current.hasActiveRegistration else {
            await presentErrorDeferred(AppError.registrationRequired)
            return
        }
        do {
            try await services.voterRepository.clearAll(session: current)
            await Task.yield()
            filterCriteria = FilterCriteria()
            services.sessionStore.saveFilters(filterCriteria)
        } catch {
            await presentErrorDeferred(error)
        }
    }

    private func presentErrorDeferred(_ error: Error) async {
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(400))
        handle(error)
    }

    func saveFilters(_ criteria: FilterCriteria) {
        filterCriteria = criteria
        services.sessionStore.saveFilters(criteria)
    }

    func navigate(to route: AppRoute) {
        navigationPath.append(route)
    }

    // MARK: - Private

    private func applyPhase(for restored: UserSession) {
        if restored.hasActiveRegistration {
            phase = .main
        } else if restored.isLoggedIn {
            phase = .registration
        } else {
            phase = .login
        }
    }

    /// Refreshes tokens and syncs voters without blocking navigation or showing errors on launch.
    private func syncInBackground() async {
        do {
            try await refreshSessionAndSync()
        } catch {
            // Keep home screen; cached voters remain available offline.
        }
    }

    private func refreshSessionAndSync() async throws {
        var working = session
        try await SessionManager.prepareForAPI(
            authService: services.authService,
            sessionStore: services.sessionStore,
            session: &working
        )
        session = working
        guard let current = session, current.hasActiveRegistration else {
            throw AppError.registrationRequired
        }
        try await services.voterRepository.sync(session: current)
        session = services.sessionStore.loadSession() ?? session
    }
}
