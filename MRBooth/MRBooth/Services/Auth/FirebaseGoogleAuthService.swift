//
//  FirebaseGoogleAuthService.swift
//  MRBooth
//
//  Login state and tokens are persisted via SessionStore (UserDefaults only).
//  Google Sign-In is used for the interactive OAuth flow; tokens are then saved locally.
//

import Foundation

#if canImport(FirebaseCore) && canImport(FirebaseAuth) && canImport(GoogleSignIn)
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
#endif

/// Firebase Authentication with Google + Drive/Sheets OAuth scopes.
final class FirebaseGoogleAuthService: AuthServiceProtocol, @unchecked Sendable {
    private let store: SessionStore

    static var isConfigured: Bool {
        #if canImport(FirebaseCore)
        return Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        #else
        return false
        #endif
    }

    init(store: SessionStore = .shared) {
        self.store = store
    }

    func restoreSession() async throws -> UserSession? {
        #if canImport(FirebaseAuth) && canImport(GoogleSignIn)
        guard Self.isConfigured else { return validatedSavedSession() }

        guard var session = validatedSavedSession() else { return nil }

        configureGoogleSignInIfNeeded()

        if session.hasActiveRegistration && session.hasGoogleDriveAccess {
            if let token = try? await refreshAccessToken() {
                session.accessToken = token
                store.saveSession(session)
            }
        }

        return session
        #else
        return validatedSavedSession()
        #endif
    }

    func signIn() async throws -> UserSession {
        #if canImport(FirebaseAuth) && canImport(GoogleSignIn)
        guard Self.isConfigured else { throw AppError.googleServiceUnavailable }
        guard let presenter = await MainActor.run(body: { UIApplication.topViewController }) else {
            throw AppError.googleServiceUnavailable
        }

        configureGoogleSignInIfNeeded()

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AppError.notAuthenticated
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        _ = try await Auth.auth().signIn(with: credential)

        let saved = store.loadSession()
        guard var session = buildSession(googleUser: result.user, saved: saved) else {
            throw AppError.notAuthenticated
        }
        session.lastLoginAt = Date()
        store.saveSession(session)
        return session
        #else
        throw AppError.googleServiceUnavailable
        #endif
    }

    func refreshAccessToken() async throws -> String {
        #if canImport(GoogleSignIn)
        guard Self.isConfigured else { throw AppError.googleServiceUnavailable }

        guard var session = store.loadSession(), session.isLoggedIn else {
            throw AppError.notAuthenticated
        }

        configureGoogleSignInIfNeeded()

        if let token = try? await refreshAccessTokenUsingStoredRefresh() {
            return token
        }

        if let user = GIDSignIn.sharedInstance.currentUser {
            try await refreshGoogleTokensIfNeeded(user)
            let token = user.accessToken.tokenString
            persistTokens(from: user, into: &session)
            store.saveSession(session)
            return token
        }

        if let token = session.accessToken, !token.isEmpty {
            return token
        }

        throw AppError.notAuthenticated
        #else
        throw AppError.googleServiceUnavailable
        #endif
    }

    func requestDriveAndSheetsAccess() async throws -> String {
        #if canImport(GoogleSignIn)
        guard Self.isConfigured else { throw AppError.googleServiceUnavailable }

        configureGoogleSignInIfNeeded()

        if GIDSignIn.sharedInstance.currentUser == nil {
            _ = try await signIn()
        }

        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw AppError.notAuthenticated
        }

        let granted = Set(user.grantedScopes ?? [])
        let needsScopes = !GoogleScopes.registration.allSatisfy { granted.contains($0) }

        let activeUser: GIDGoogleUser
        if needsScopes {
            guard let presenter = await MainActor.run(body: { UIApplication.topViewController }) else {
                throw AppError.googleServiceUnavailable
            }
            let result = try await user.addScopes(GoogleScopes.registration, presenting: presenter)
            activeUser = result.user
        } else {
            activeUser = user
        }

        let token = activeUser.accessToken.tokenString
        if var session = store.loadSession() {
            persistTokens(from: activeUser, into: &session)
            session.hasGoogleDriveAccess = true
            store.saveSession(session)
        }
        return token
        #else
        throw AppError.googleServiceUnavailable
        #endif
    }

    func signOut() async throws {
        #if canImport(FirebaseAuth) && canImport(GoogleSignIn)
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        #endif
        store.clearSession()
    }

    // MARK: - Private

    private func validatedSavedSession() -> UserSession? {
        guard var saved = store.loadSession(), saved.isLoggedIn else {
            return nil
        }
        saved.reconcileRegistration()
        return saved
    }

    #if canImport(GoogleSignIn) && canImport(FirebaseAuth)
    private struct GoogleTokenResponse: Decodable {
        let accessToken: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
        }
    }

    private func configureGoogleSignInIfNeeded() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    private func buildSession(googleUser: GIDGoogleUser, saved: UserSession?) -> UserSession? {
        let firebaseUser = Auth.auth().currentUser
        let email = firebaseUser?.email ?? googleUser.profile?.email ?? saved?.email ?? ""
        guard !email.isEmpty else { return nil }

        let granted = Set(googleUser.grantedScopes ?? [])
        let hasDrive = GoogleScopes.registration.allSatisfy { granted.contains($0) }
            || (saved?.hasGoogleDriveAccess ?? false)

        var session = UserSession(
            email: email,
            displayName: firebaseUser?.displayName ?? googleUser.profile?.name ?? saved?.displayName ?? "User",
            profileImageURL: firebaseUser?.photoURL?.absoluteString
                ?? googleUser.profile?.imageURL(withDimension: 120)?.absoluteString
                ?? saved?.profileImageURL,
            accessToken: googleUser.accessToken.tokenString,
            refreshToken: refreshedTokenString(from: googleUser) ?? saved?.refreshToken,
            isRegistered: saved?.isRegistered ?? false,
            hasGoogleDriveAccess: hasDrive,
            booth: saved?.booth,
            lastLoginAt: saved?.lastLoginAt ?? Date()
        )
        return session
    }

    private func persistTokens(from googleUser: GIDGoogleUser, into session: inout UserSession) {
        session.accessToken = googleUser.accessToken.tokenString
        if let refresh = refreshedTokenString(from: googleUser) {
            session.refreshToken = refresh
        }
        session.email = Auth.auth().currentUser?.email ?? googleUser.profile?.email ?? session.email
        session.displayName = Auth.auth().currentUser?.displayName ?? googleUser.profile?.name ?? session.displayName
        let granted = Set(googleUser.grantedScopes ?? [])
        if GoogleScopes.registration.allSatisfy({ granted.contains($0) }) {
            session.hasGoogleDriveAccess = true
        }
    }

    private func refreshAccessTokenUsingStoredRefresh() async throws -> String {
        guard var session = store.loadSession(),
              let refreshToken = session.refreshToken,
              !refreshToken.isEmpty,
              let clientID = FirebaseApp.app()?.options.clientID else {
            throw AppError.notAuthenticated
        }

        var request = URLRequest(url: APIConstants.OAuth.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        func encoded(_ value: String) -> String {
            value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
        }

        let body = [
            "grant_type=refresh_token",
            "refresh_token=\(encoded(refreshToken))",
            "client_id=\(encoded(clientID))"
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw AppError.notAuthenticated
        }

        let decoded = try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
        session.accessToken = decoded.accessToken
        store.saveSession(session)
        return decoded.accessToken
    }

    private func refreshedTokenString(from googleUser: GIDGoogleUser) -> String? {
        let token = googleUser.refreshToken.tokenString
        return token.isEmpty ? nil : token
    }

    private func refreshGoogleTokensIfNeeded(_ user: GIDGoogleUser) async throws {
        if user.accessToken.expirationDate ?? .distantPast <= Date().addingTimeInterval(60) {
            _ = try await user.refreshTokensIfNeeded()
        }
    }
    #endif
}
