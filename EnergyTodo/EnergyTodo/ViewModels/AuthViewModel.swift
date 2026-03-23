import Foundation
import Auth

@Observable
final class AuthViewModel {

    enum AuthState {
        case loading
        case unauthenticated
        case needsOnboarding
        case authenticated
    }

    var state: AuthState = .loading
    var email = ""
    var password = ""
    var errorMessage: String?
    var isProcessing = false

    private let authService = AuthService()
    private let cycleService = CycleService()

    /// Check for existing session on launch.
    func checkSession() async {
        if let session = await authService.currentSession() {
            _cachedUserId = session.user.id
            await checkOnboardingStatus(userId: session.user.id)
        } else {
            state = .unauthenticated
        }
    }

    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        isProcessing = true
        errorMessage = nil
        do {
            let session = try await authService.signIn(email: email, password: password)
            _cachedUserId = session.user.id
            await checkOnboardingStatus(userId: session.user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func signUp() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        isProcessing = true
        errorMessage = nil
        do {
            let session = try await authService.signUp(email: email, password: password)
            if let session {
                _cachedUserId = session.user.id
                await checkOnboardingStatus(userId: session.user.id)
            } else {
                // Email confirmation required
                errorMessage = "Check your email for a confirmation link, then sign in."
                state = .unauthenticated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func signOut() async {
        do {
            try await authService.signOut()
            state = .unauthenticated
            email = ""
            password = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// After auth, check if user has completed onboarding (has a cycle).
    private func checkOnboardingStatus(userId: UUID) async {
        do {
            let cycle = try await cycleService.fetchCycle(userId: userId)
            state = cycle == nil ? .needsOnboarding : .authenticated
        } catch {
            state = .needsOnboarding
        }
    }

    func getCurrentUserId() async -> UUID? {
        await authService.currentUserId()
    }

    var currentUserId: UUID? {
        // Cached from last session check
        _cachedUserId
    }

    private var _cachedUserId: UUID?
}
