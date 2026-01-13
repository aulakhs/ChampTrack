import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo section
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.championBlue)

                        Text("ChampTrack")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)

                        Text("Empowering Young Champions,\nOne Goal at a Time")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Login form
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)

                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.textSecondary)
                                TextField("Enter your email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            .padding()
                            .background(Color.softBackground)
                            .cornerRadius(12)
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)

                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.textSecondary)
                                SecureField("Enter your password", text: $password)
                                    .textContentType(.password)
                            }
                            .padding()
                            .background(Color.softBackground)
                            .cornerRadius(12)
                        }

                        // Forgot password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.championBlue)
                        }

                        // Error message
                        if let error = authService.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.accentRed)
                                .padding(.horizontal)
                        }

                        // Sign in button
                        PrimaryButton(
                            title: "Sign In",
                            action: signIn,
                            isLoading: authService.isLoading,
                            isDisabled: !isFormValid
                        )
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)

                    // Sign up link
                    VStack(spacing: 12) {
                        Text("Don't have an account?")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)

                        PrimaryButton(
                            title: "Create Account",
                            action: { showSignUp = true },
                            style: .secondary
                        )
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Color.white)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    private func signIn() {
        Task {
            await authService.signIn(email: email, password: password)
        }
    }
}

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 50))
                    .foregroundColor(.championBlue)
                    .padding(.top, 40)

                Text("Reset Password")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)

                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.textSecondary)
                        TextField("Enter your email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color.softBackground)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                if showSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.success)
                        Text("Password reset link sent!")
                            .foregroundColor(.success)
                    }
                    .font(.subheadline)
                }

                PrimaryButton(
                    title: "Send Reset Link",
                    action: resetPassword,
                    isLoading: authService.isLoading,
                    isDisabled: email.isEmpty
                )
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func resetPassword() {
        Task {
            let success = await authService.resetPassword(email: email)
            if success {
                showSuccess = true
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                dismiss()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
}
