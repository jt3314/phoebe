import Foundation
import GoogleSignIn
import Supabase

/// Handles Google Sign-In flow and Supabase session exchange.
enum GoogleAuthService {

    static let clientID = "134892810952-o63dpf9gik20maqkm1docr452p6ce5oe.apps.googleusercontent.com"

    /// The calendar readonly scope requested during sign-in.
    private static let calendarScope = "https://www.googleapis.com/auth/calendar.readonly"

    /// Configure GIDSignIn with our client ID. Call once on app launch.
    static func configure() {
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }

    /// Perform Google Sign-In with calendar scope, then create a Supabase session.
    /// Returns the Supabase session on success.
    @MainActor
    static func signIn() async throws -> Auth.Session {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            throw GoogleAuthError.noRootViewController
        }

        // Sign in with Google, requesting calendar scope
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootVC,
            hint: nil,
            additionalScopes: [calendarScope]
        )

        let user = result.user
        guard let idToken = user.idToken?.tokenString else {
            throw GoogleAuthError.missingIdToken
        }

        // Store Google tokens for Calendar API access
        KeychainService.googleAccessToken = user.accessToken.tokenString

        // Exchange Google ID token for Supabase session
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: idToken, accessToken: user.accessToken.tokenString)
        )

        return session
    }

    /// Silently refresh the Google access token.
    /// Returns the new access token, or nil if refresh fails.
    @MainActor
    static func refreshTokenIfNeeded() async -> String? {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else { return nil }

        do {
            try await currentUser.refreshTokensIfNeeded()
            let newToken = currentUser.accessToken.tokenString
            KeychainService.googleAccessToken = newToken
            return newToken
        } catch {
            return nil
        }
    }

    /// Get a valid Google access token, refreshing if needed.
    @MainActor
    static func getValidAccessToken() async -> String? {
        if let currentUser = GIDSignIn.sharedInstance.currentUser {
            if currentUser.accessToken.expirationDate ?? .distantPast > Date() {
                return currentUser.accessToken.tokenString
            }
            return await refreshTokenIfNeeded()
        }
        return KeychainService.googleAccessToken
    }

    /// Sign out of Google and clear stored tokens.
    static func signOut() {
        GIDSignIn.sharedInstance.signOut()
        KeychainService.googleAccessToken = nil
        KeychainService.googleRefreshToken = nil
    }

    /// Restore previous Google sign-in session on app launch.
    @MainActor
    static func restorePreviousSignIn() async {
        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            KeychainService.googleAccessToken = user.accessToken.tokenString
        } catch {
            // No previous session — user will need to sign in again
        }
    }

    enum GoogleAuthError: LocalizedError {
        case noRootViewController
        case missingIdToken

        var errorDescription: String? {
            switch self {
            case .noRootViewController: return "Unable to find root view controller for sign-in."
            case .missingIdToken: return "Google sign-in did not return an ID token."
            }
        }
    }
}
