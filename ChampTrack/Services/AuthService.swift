import Foundation
import SwiftUI
import Combine

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Mock users for development
    private var mockUsers: [String: (user: User, password: String)] = [:]

    init() {
        // Check for stored session
        loadStoredSession()
    }

    func signUp(email: String, password: String, displayName: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Validate email format
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return false
        }

        // Validate password
        guard isValidPassword(password) else {
            errorMessage = "Password must be at least 8 characters with letters and numbers"
            isLoading = false
            return false
        }

        // Check if user already exists
        guard mockUsers[email.lowercased()] == nil else {
            errorMessage = "An account with this email already exists"
            isLoading = false
            return false
        }

        // Create new user
        let user = User(
            email: email.lowercased(),
            displayName: displayName,
            role: .parent
        )

        mockUsers[email.lowercased()] = (user, password)
        currentUser = user
        isAuthenticated = true
        saveSession(user: user)

        isLoading = false
        return true
    }

    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // For demo purposes, accept any email/password combo
        // In production, this would validate against Firebase
        if let stored = mockUsers[email.lowercased()] {
            if stored.password == password {
                var user = stored.user
                user.lastLoginAt = Date()
                currentUser = user
                isAuthenticated = true
                saveSession(user: user)
                isLoading = false
                return true
            } else {
                errorMessage = "Incorrect password"
                isLoading = false
                return false
            }
        }

        // For demo: create user if doesn't exist
        let user = User(
            email: email.lowercased(),
            displayName: email.components(separatedBy: "@").first?.capitalized ?? "User",
            role: .parent
        )
        mockUsers[email.lowercased()] = (user, password)
        currentUser = user
        isAuthenticated = true
        saveSession(user: user)

        isLoading = false
        return true
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        clearSession()
    }

    func resetPassword(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return false
        }

        // In production, this would send a password reset email
        isLoading = false
        return true
    }

    func updateProfile(displayName: String?, photoURL: String?) async -> Bool {
        guard var user = currentUser else { return false }

        isLoading = true

        if let name = displayName {
            user.displayName = name
        }
        if let photo = photoURL {
            user.photoURL = photo
        }

        currentUser = user
        saveSession(user: user)

        isLoading = false
        return true
    }

    // MARK: - Private Methods

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters, contains letters and numbers
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d@$!%*#?&]{8,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return predicate.evaluate(with: password)
    }

    private func saveSession(user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }

    private func loadStoredSession() {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isAuthenticated = true
        }
    }

    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}
