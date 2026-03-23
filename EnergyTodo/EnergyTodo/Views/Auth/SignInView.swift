import SwiftUI

struct SignInView: View {
    @Bindable var authVM: AuthViewModel
    @State private var isSignUp = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo / Title
            VStack(spacing: 8) {
                Text("Energy Todo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)

                Text("Schedule tasks around your energy cycles")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Form
            VStack(spacing: 16) {
                TextField("Email", text: $authVM.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $authVM.password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .textFieldStyle(.roundedBorder)

                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
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
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(authVM.isProcessing)
            }
            .padding(.horizontal, 32)

            Button {
                isSignUp.toggle()
                authVM.errorMessage = nil
            } label: {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.footnote)
            }

            Spacer()
        }
        .padding()
    }
}
