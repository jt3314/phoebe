import SwiftUI
import GoogleSignIn

struct SignInView: View {
    @Bindable var authVM: AuthViewModel
    @State private var isSignUp = false
    @State private var showEmailForm = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 8) {
                    Text("Phoebe")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Theme.primary)

                    Text("Work with your cycle, not against it. Schedule tasks around your energy levels.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Google Sign-In button
                VStack(spacing: 16) {
                    Button {
                        Task { await authVM.signInWithGoogle() }
                    } label: {
                        if authVM.isProcessing && !showEmailForm {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "g.circle.fill")
                                    .font(.title3)
                                Text("Continue with Google")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                    }
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .disabled(authVM.isProcessing)

                    if let error = authVM.errorMessage, !showEmailForm {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Theme.destructive)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)

                // Divider
                HStack {
                    Rectangle()
                        .fill(Theme.cardBorder)
                        .frame(height: 1)
                    Text("or")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedForeground)
                    Rectangle()
                        .fill(Theme.cardBorder)
                        .frame(height: 1)
                }
                .padding(.horizontal, 40)

                // Email/password fallback
                if showEmailForm {
                    emailFormCard
                } else {
                    Button {
                        withAnimation { showEmailForm = true }
                    } label: {
                        Text("Sign in with email instead")
                            .font(.footnote)
                            .foregroundStyle(Theme.primary)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Email Form (Fallback)

    private var emailFormCard: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $authVM.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )

            SecureField("Password", text: $authVM.password)
                .textContentType(isSignUp ? .newPassword : .password)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )

            if let error = authVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Theme.destructive)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    if isSignUp {
                        await authVM.signUp()
                    } else {
                        await authVM.signIn()
                    }
                }
            } label: {
                if authVM.isProcessing {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                } else {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .disabled(authVM.isProcessing)

            Button {
                isSignUp.toggle()
                authVM.errorMessage = nil
            } label: {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.footnote)
                    .foregroundStyle(Theme.primary)
            }
        }
        .padding(24)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.cardBorder, lineWidth: 0.5)
        )
        .padding(.horizontal, 24)
    }
}
