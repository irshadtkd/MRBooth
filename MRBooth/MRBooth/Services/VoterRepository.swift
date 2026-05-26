//
//  VoterRepository.swift
//  MRBooth
//

import Foundation

@MainActor
final class VoterRepository: ObservableObject {
    @Published private(set) var voters: [Voter] = []
    @Published private(set) var lastSyncedAt: Date?
    @Published private(set) var isLoading = false

    private let sheetsService: SheetsServiceProtocol
    private let authService: AuthServiceProtocol
    private let sessionStore: SessionStore

    init(
        sheetsService: SheetsServiceProtocol,
        authService: AuthServiceProtocol,
        sessionStore: SessionStore = .shared
    ) {
        self.sheetsService = sheetsService
        self.authService = authService
        self.sessionStore = sessionStore
    }

    func sync(session: UserSession) async throws {
        let working = try await preparedSession(from: session)
        guard let booth = working.booth, let sheetID = booth.sheetID, let token = working.accessToken else {
            throw AppError.registrationRequired
        }
        isLoading = true
        defer { isLoading = false }
        voters = try await sheetsService.fetchVoters(sheetID: sheetID, accessToken: token).ensuringUniqueIDs()
        lastSyncedAt = Date()
    }

    func loadCached() {
        voters = sessionStore.loadLocalVoters()
    }

    func addVoters(_ newVoters: [Voter], session: UserSession) async throws {
        let working = try await preparedSession(from: session)
        guard let booth = working.booth, let sheetID = booth.sheetID, let token = working.accessToken else {
            throw AppError.registrationRequired
        }
        try await sheetsService.appendVoters(newVoters, sheetID: sheetID, accessToken: token)
        mergeIntoLocalCache(newVoters)
        do {
            try await sync(session: working)
        } catch {
            // Rows were appended; keep merged local data if refetch fails on legacy sheet layouts.
        }
    }

    private func mergeIntoLocalCache(_ newVoters: [Voter]) {
        var merged = sessionStore.loadLocalVoters()
        for voter in newVoters {
            let key = VoterIDParser.normalize(voter.voterID)
            if key.isEmpty {
                merged.append(voter)
            } else if !merged.contains(where: { VoterIDParser.normalize($0.voterID) == key }) {
                merged.append(voter)
            }
        }
        let unique = merged.ensuringUniqueIDs()
        sessionStore.saveLocalVoters(unique)
        voters = unique
        lastSyncedAt = Date()
    }

    func update(_ voter: Voter, session: UserSession) async throws {
        let working = try await preparedSession(from: session)
        guard let booth = working.booth, let sheetID = booth.sheetID, let token = working.accessToken else {
            throw AppError.registrationRequired
        }
        var updated = voter
        updated.updatedAt = Date()
        try await sheetsService.updateVoter(updated, sheetID: sheetID, accessToken: token)
        try await sync(session: working)
    }

    func delete(_ voter: Voter, session: UserSession) async throws {
        let working = try await preparedSession(from: session)
        guard let booth = working.booth, let sheetID = booth.sheetID, let token = working.accessToken else {
            throw AppError.registrationRequired
        }
        try await sheetsService.deleteVoter(voter, sheetID: sheetID, accessToken: token)
        try await sync(session: working)
    }

    func clearAll(session: UserSession) async throws {
        let working = try await preparedSession(from: session)
        guard let booth = working.booth, let sheetID = booth.sheetID, let token = working.accessToken else {
            throw AppError.registrationRequired
        }
        try await sheetsService.clearAllVoters(sheetID: sheetID, accessToken: token)
        await Task.yield()
        voters = []
        lastSyncedAt = Date()
    }

    private func preparedSession(from session: UserSession) async throws -> UserSession {
        var working: UserSession? = session
        try await SessionManager.prepareForAPI(
            authService: authService,
            sessionStore: sessionStore,
            session: &working
        )
        guard let working else { throw AppError.notAuthenticated }
        return working
    }

    func isDuplicate(voterID: String, excluding id: String? = nil) -> Bool {
        let normalized = VoterIDParser.normalize(voterID)
        guard !normalized.isEmpty else { return false }
        return voters.contains {
            VoterIDParser.normalize($0.voterID) == normalized && $0.id != id
        }
    }

    func dashboardStats() -> DashboardStats {
        let voted = voters.filter { $0.votingStatus == .voted }.count
        return DashboardStats(total: voters.count, voted: voted)
    }

    func partyReport() -> [PartyReportItem] {
        let total = max(voters.count, 1)
        return PartyStatus.allCases.map { party in
            let count = voters.filter { $0.partyStatus == party }.count
            return PartyReportItem(
                party: party,
                count: count,
                percentage: Double(count) / Double(total) * 100
            )
        }
    }

    func filtered(_ criteria: FilterCriteria, search: String = "") -> [Voter] {
        voters.filter { voter in
            let matchesFilter = criteria.isActive ? criteria.matches(voter) : true
            let matchesSearch: Bool
            if search.isEmpty {
                matchesSearch = true
            } else {
                let q = search.lowercased()
                matchesSearch = voter.name.lowercased().contains(q)
                    || voter.voterID.lowercased().contains(q)
                    || voter.serialNumber.lowercased().contains(q)
            }
            return matchesFilter && matchesSearch
        }
    }
}
