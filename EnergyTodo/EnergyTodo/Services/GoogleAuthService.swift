import Foundation
import AuthenticationServices
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

    /// Perform Google Sign-In via Supabase OAuth (opens in-app browser).
    /// The session comes back via URL redirect handled by onOpenURL in EnergyTodoApp.
    @MainActor
    static func signIn() async throws {
        try await supabase.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: "com.tinyglobe.phoebe://login-callback"),
            scopes: calendarScope
        )
    }

    // MARK: - Token Management

    /// Silently refresh the Google access token.
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
        // Fall back to stored token from Supabase OAuth session
        if let session = try? await supabase.auth.session,
           let providerToken = session.providerToken {
            return providerToken
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
            // No previous session — calendar sync will use Supabase provider token
        }
    }

    enum GoogleAuthError: LocalizedError {
        case noRootViewController
        case missingIdToken

        var errorDescription: String? {
            switch self {
            case .noRootViewController: return "Unable to find root view controller for sign-in."
            case .missingIdToken: return "Google sign-in did not return a session."
            }
        }
    }
}
