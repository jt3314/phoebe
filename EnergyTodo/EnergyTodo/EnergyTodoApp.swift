import SwiftUI

@main
struct EnergyTodoApp: App {
    @State private var authVM = AuthViewModel()

    init() {
        GoogleAuthService.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch authVM.state {
                case .loading:
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .unauthenticated:
                    SignInView(authVM: authVM)
                case .needsOnboarding:
                    OnboardingContainerView(authVM: authVM)
                case .authenticated:
                    MainTabView(authVM: authVM)
                }
            }
            .task {
                await authVM.checkSession()
            }
            .onOpenURL { url in
                Task {
                    try? await supabase.auth.session(from: url)
                    await authVM.handleSessionFromURL()
                }
            }
        }
    }
}
