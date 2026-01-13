import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var acceptedTerms = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("Join ChampTrack and start empowering your young champions")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Form
                VStack(spacing: 20) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)

                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.textSecondary)
                            TextField("Enter your name", text: $displayName)
                                .textContentType(.name)
                                .autocapitalization(.words)
                        }
                        .padding()
                        .background(Color.softBackground)
                        .cornerRadius(12)
                    }

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
                            SecureField("Create a password", text: $password)
                                .textContentType(.newPassword)
                        }
                        .padding()
                        .background(Color.softBackground)
                        .cornerRadius(12)

                        // Password requirements
                        VStack(alignment: .leading, spacing: 4) {
                            PasswordRequirement(
                                text: "At least 8 characters",
                                isMet: password.count >= 8
                            )
                            PasswordRequirement(
                                text: "Contains letters and numbers",
                                isMet: containsLettersAndNumbers
                            )
                        }
                        .padding(.top, 4)
                    }

                    // Confirm password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)

                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.textSecondary)
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textContentType(.newPassword)

                            if !confirmPassword.isEmpty {
                                Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(passwordsMatch ? .success : .accentRed)
                            }
                        }
                        .padding()
                        .background(Color.softBackground)
                        .cornerRadius(12)
                    }

                    // Terms and conditions
                    HStack(alignment: .top, spacing: 12) {
                        Button(action: { acceptedTerms.toggle() }) {
                            Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundColor(acceptedTerms ? .championBlue : .textSecondary)
                        }

                        Text("I agree to the Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 8)

                    // Error message
                    if let error = authService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.accentRed)
                    }

                    // Sign up button
                    PrimaryButton(
                        title: "Create Account",
                        action: signUp,
                        isLoading: authService.isLoading,
                        isDisabled: !isFormValid
                    )
                    .padding(.top, 8)
                }
                .padding(.horizontal)

                // Sign in link
                HStack {
                    Text("Already have an account?")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    Button("Sign In") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.championBlue)
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !displayName.isEmpty &&
        password.count >= 8 &&
        containsLettersAndNumbers &&
        passwordsMatch &&
        acceptedTerms
    }

    private var containsLettersAndNumbers: Bool {
        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasLetter && hasNumber
    }

    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    private func signUp() {
        Task {
            await authService.signUp(email: email, password: password, displayName: displayName)
        }
    }
}

struct PasswordRequirement: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(isMet ? .success : .textSecondary)

            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .success : .textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthService())
    }
}
