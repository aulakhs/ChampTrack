import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var dataService: DataService
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            List {
                // Profile section
                Section {
                    NavigationLink(destination: ProfileSettingsView()) {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.championBlue)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(initials)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(authService.currentUser?.displayName ?? "User")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)

                                Text(authService.currentUser?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // Family section
                Section("Family") {
                    NavigationLink(destination: ChildListView()) {
                        SettingsRow(icon: "person.2.fill", title: "Children", color: .championBlue)
                    }

                    NavigationLink(destination: FamilyMembersView()) {
                        SettingsRow(icon: "person.2.badge.gearshape.fill", title: "Family Sharing", color: .energyGreen)
                    }
                }

                // App settings
                Section("Settings") {
                    NavigationLink(destination: NotificationSettingsView()) {
                        SettingsRow(icon: "bell.fill", title: "Notifications", color: .victoryGold)
                    }

                    NavigationLink(destination: CalendarSettingsView()) {
                        SettingsRow(icon: "calendar", title: "Calendar Integration", color: .accentPurple)
                    }

                    NavigationLink(destination: AppearanceSettingsView()) {
                        SettingsRow(icon: "paintbrush.fill", title: "Appearance", color: .accentRed)
                    }
                }

                // Support section
                Section("Support") {
                    NavigationLink(destination: HelpView()) {
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help & FAQ", color: .championBlue)
                    }

                    Button(action: contactSupport) {
                        SettingsRow(icon: "envelope.fill", title: "Contact Support", color: .energyGreen)
                    }

                    NavigationLink(destination: AboutView()) {
                        SettingsRow(icon: "info.circle.fill", title: "About", color: .textSecondary)
                    }
                }

                // Account section
                Section("Account") {
                    Button(action: { showLogoutAlert = true }) {
                        SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", color: .accentRed)
                    }
                }

                // Version info
                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    private var initials: String {
        let name = authService.currentUser?.displayName ?? "U"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(name.prefix(2)).uppercased()
    }

    private func contactSupport() {
        // Would open email or support URL
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .cornerRadius(6)

            Text(title)
                .foregroundColor(.textPrimary)
        }
    }
}

// MARK: - Profile Settings

struct ProfileSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var displayName = ""
    @State private var isSaving = false

    var body: some View {
        Form {
            Section("Profile Information") {
                TextField("Display Name", text: $displayName)
                Text(authService.currentUser?.email ?? "")
                    .foregroundColor(.textSecondary)
            }

            Section {
                Button(action: saveProfile) {
                    HStack {
                        Text("Save Changes")
                        if isSaving {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(displayName.isEmpty || isSaving)
            }

            Section("Security") {
                NavigationLink("Change Password") {
                    ChangePasswordView()
                }
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            displayName = authService.currentUser?.displayName ?? ""
        }
    }

    private func saveProfile() {
        isSaving = true
        Task {
            await authService.updateProfile(displayName: displayName, photoURL: nil)
            isSaving = false
        }
    }
}

struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    var body: some View {
        Form {
            Section {
                SecureField("Current Password", text: $currentPassword)
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)
            }

            Section {
                Button("Update Password") {
                    // Would update password
                }
                .disabled(currentPassword.isEmpty || newPassword.isEmpty || newPassword != confirmPassword)
            }
        }
        .navigationTitle("Change Password")
    }
}

// MARK: - Family Members

struct FamilyMembersView: View {
    @EnvironmentObject var dataService: DataService
    @State private var showJoinFamily = false
    @State private var joinCode = ""
    @State private var isJoining = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false
    @State private var showLeaveAlert = false

    var body: some View {
        List {
            // Family Code Section
            Section {
                VStack(alignment: .center, spacing: 12) {
                    Text("Your Family Code")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text(dataService.familyCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.championBlue)
                        .padding()
                        .background(Color.championBlue.opacity(0.1))
                        .cornerRadius(12)

                    Text("Share this code with family members\nso they can sync with your data")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)

                    Button(action: copyCode) {
                        Label("Copy Code", systemImage: "doc.on.doc")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .tint(.championBlue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            // Join Family Section
            Section {
                Button(action: { showJoinFamily = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.energyGreen)
                        Text("Join Another Family")
                            .foregroundColor(.textPrimary)
                    }
                }
            } footer: {
                Text("If your spouse already set up the app, enter their family code to sync data.")
            }

            // Family Info
            Section("Current Family") {
                if let family = dataService.family {
                    HStack {
                        Text("Family Name")
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(family.name)
                            .foregroundColor(.textPrimary)
                    }

                    HStack {
                        Text("Members")
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text("\(family.members.count)")
                            .foregroundColor(.textPrimary)
                    }
                }
            }

            // Leave Family
            Section {
                Button(action: { showLeaveAlert = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.accentRed)
                        Text("Leave Family & Start New")
                            .foregroundColor(.accentRed)
                    }
                }
            } footer: {
                Text("This will disconnect you from the current family and create a new one. Your data will remain with the family you leave.")
            }
        }
        .navigationTitle("Family Sharing")
        .sheet(isPresented: $showJoinFamily) {
            joinFamilySheet
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {}
        } message: {
            Text("Successfully joined the family! Your data will now sync.")
        }
        .alert("Leave Family?", isPresented: $showLeaveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                dataService.leaveFamily()
            }
        } message: {
            Text("Are you sure you want to leave this family? You'll start a new family and lose access to shared data.")
        }
    }

    private var joinFamilySheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.championBlue)

                Text("Join a Family")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Enter the family code shared with you")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                TextField("Family Code", text: $joinCode)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                Button(action: joinFamily) {
                    HStack {
                        if isJoining {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isJoining ? "Joining..." : "Join Family")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(joinCode.count >= 8 ? Color.championBlue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(joinCode.count < 8 || isJoining)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showJoinFamily = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func copyCode() {
        UIPasteboard.general.string = dataService.familyCode
    }

    private func joinFamily() {
        isJoining = true
        dataService.joinFamilyByCode(joinCode) { success, error in
            isJoining = false
            if success {
                showJoinFamily = false
                showSuccess = true
                joinCode = ""
            } else {
                errorMessage = error
                showError = true
            }
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @State private var pushEnabled = true
    @State private var emailEnabled = true
    @State private var scheduleReminders = true
    @State private var nutritionReminders = true
    @State private var achievementAlerts = true
    @State private var reminderTime = 30

    var body: some View {
        Form {
            Section("Channels") {
                Toggle("Push Notifications", isOn: $pushEnabled)
                Toggle("Email Notifications", isOn: $emailEnabled)
            }

            Section("Notification Types") {
                Toggle("Schedule Reminders", isOn: $scheduleReminders)
                Toggle("Nutrition Reminders", isOn: $nutritionReminders)
                Toggle("Achievement Alerts", isOn: $achievementAlerts)
            }

            Section("Timing") {
                Picker("Remind Before Activity", selection: $reminderTime) {
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("2 hours").tag(120)
                }
            }
        }
        .navigationTitle("Notifications")
    }
}

// MARK: - Calendar Settings

struct CalendarSettingsView: View {
    @State private var calendarSyncEnabled = false

    var body: some View {
        Form {
            Section {
                Toggle("Enable Calendar Sync", isOn: $calendarSyncEnabled)
            }

            if calendarSyncEnabled {
                Section("Google Calendar") {
                    Button("Connect Google Calendar") {
                        // Would initiate OAuth flow
                    }
                }
            }

            Section(footer: Text("Calendar sync allows activities to appear in your device calendar.")) {
                EmptyView()
            }
        }
        .navigationTitle("Calendar Integration")
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @State private var selectedTheme = 0

    var body: some View {
        Form {
            Section("Theme") {
                Picker("App Theme", selection: $selectedTheme) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .navigationTitle("Appearance")
    }
}

// MARK: - Help & About

struct HelpView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                HelpRow(question: "How do I add a child?", answer: "Go to Settings > Children > tap the + button")
                HelpRow(question: "How do I schedule an activity?", answer: "Go to Schedule tab > tap the + button")
                HelpRow(question: "How does the points system work?", answer: "Children earn points for completing activities, meeting nutrition goals, and achieving milestones")
            }

            Section("Features") {
                HelpRow(question: "What is nutrition tracking?", answer: "Log your child's meals to track their nutritional intake against recommended targets")
                HelpRow(question: "How do transportation assignments work?", answer: "Assign parents to dropoff and pickup duties for each activity")
            }
        }
        .navigationTitle("Help & FAQ")
    }
}

struct HelpRow: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(question)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.textSecondary)
                }
            }

            if isExpanded {
                Text(answer)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.championBlue)

                    Text("ChampTrack")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Empowering Young Champions,\nOne Goal at a Time")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)

                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            Section {
                Link("Privacy Policy", destination: URL(string: "https://champtrack.app/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://champtrack.app/terms")!)
            }

            Section {
                Text("Made with love for families everywhere")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("About")
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
        .environmentObject(DataService())
}
