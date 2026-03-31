import Foundation
import Supabase
import Auth

/// Handles all Supabase authentication operations.
struct AuthService {

    /// Sign in with email and password.
    func signIn(email: String, password: String) async throws -> Auth.Session {
        try await supabase.auth.signIn(email: email, password: password)
    }

    /// Sign up with email and password.
    /// Returns a session if email confirmation is disabled, nil if confirmation is required.
    func signUp(email: String, password: String) async throws -> Auth.Session? {
        let response = try await supabase.auth.signUp(email: email, password: password)
        return response.session
    }

    /// Sign out the current user.
    func signOut() async throws {
        try await supabase.auth.signOut()
    }

    /// Get the current session, if any.
    func currentSession() async -> Auth.Session? {
        try? await supabase.auth.session
    }

    /// Get the current user's ID.
    func currentUserId() async -> UUID? {
        try? await supabase.auth.session.user.id
    }

    /// Listen for auth state changes.
    func authStateChanges() -> AsyncStream<(event: AuthChangeEvent, session: Auth.Session?)> {
        AsyncStream { continuation in
            let task = Task {
                for await (event, session) in supabase.auth.authStateChanges {
                    continuation.yield((event: event, session: session))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Sign in with a Google ID token via Supabase.
    func signInWithGoogle(idToken: String, accessToken: String) async throws -> Auth.Session {
        try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: idToken, accessToken: accessToken)
        )
    }

    enum AuthError: LocalizedError {
        case noSession

        var errorDescription: String? {
            switch self {
            case .noSession: return "No session returned after sign up. Please check your email for verification."
            }
        }
    }
}
