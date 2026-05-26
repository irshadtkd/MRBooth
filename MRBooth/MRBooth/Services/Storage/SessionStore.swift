//
//  SessionStore.swift
//  MRBooth
//
//  App session, filters, and local voters are persisted in UserDefaults only (no Keychain).
//

import Foundation

final class SessionStore: GeminiAPIKeyProviding, @unchecked Sendable {
    static let shared = SessionStore()
    private let sessionKey = "mrbooth.user.session"
    private let registrationDraftKey = "mrbooth.registration.draft"
    private let filtersKey = "mrbooth.filter.criteria"
    private let votersKey = "mrbooth.local.voters"
    private let geminiAPIKeyKey = APIConstants.Keys.geminiAPIKeyUserDefaults
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func loadSession() -> UserSession? {
        guard let data = defaults.data(forKey: sessionKey) else { return nil }
        guard var session = try? decoder.decode(UserSession.self, from: data) else { return nil }
        session.reconcileRegistration()
        return session
    }

    func saveSession(_ session: UserSession) {
        var normalized = session
        normalized.reconcileRegistration()
        guard let data = try? encoder.encode(normalized) else { return }
        defaults.set(data, forKey: sessionKey)
    }

    func clearSession() {
        defaults.removeObject(forKey: sessionKey)
        defaults.removeObject(forKey: registrationDraftKey)
        defaults.removeObject(forKey: votersKey)
    }

    func loadRegistrationDraft() -> RegistrationDraft? {
        guard let data = defaults.data(forKey: registrationDraftKey) else { return nil }
        return try? decoder.decode(RegistrationDraft.self, from: data)
    }

    func saveRegistrationDraft(_ draft: RegistrationDraft) {
        guard let data = try? encoder.encode(draft) else { return }
        defaults.set(data, forKey: registrationDraftKey)
    }

    func clearRegistrationDraft() {
        defaults.removeObject(forKey: registrationDraftKey)
    }

    func loadFilters() -> FilterCriteria {
        guard let data = defaults.data(forKey: filtersKey),
              let criteria = try? decoder.decode(FilterCriteria.self, from: data) else {
            return FilterCriteria()
        }
        return criteria
    }

    func saveFilters(_ filters: FilterCriteria) {
        guard let data = try? encoder.encode(filters) else { return }
        defaults.set(data, forKey: filtersKey)
    }

    func loadLocalVoters() -> [Voter] {
        guard let data = defaults.data(forKey: votersKey),
              let voters = try? decoder.decode([Voter].self, from: data) else {
            return []
        }
        return voters.ensuringUniqueIDs()
    }

    func saveLocalVoters(_ voters: [Voter]) {
        guard let data = try? encoder.encode(voters) else { return }
        defaults.set(data, forKey: votersKey)
    }

    func loadGeminiAPIKey() -> String? {
        guard let key = defaults.string(forKey: geminiAPIKeyKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty else {
            return nil
        }
        return key
    }

    func saveGeminiAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(trimmed, forKey: geminiAPIKeyKey)
    }
}
