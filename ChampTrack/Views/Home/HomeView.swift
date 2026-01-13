import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var authService: AuthService
    @State private var selectedChild: Child?
    @State private var showAddChild = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome header
                    welcomeHeader

                    // Child selector
                    if !dataService.children.isEmpty {
                        childSelector
                    }

                    // Quick stats
                    if let child = selectedChild ?? dataService.children.first {
                        quickStatsSection(for: child)
                    }

                    // Upcoming activities
                    upcomingActivitiesSection

                    // Active goals
                    if let child = selectedChild ?? dataService.children.first {
                        activeGoalsSection(for: child)
                    }

                    // Conflicts alert
                    conflictsSection
                }
                .padding()
            }
            .background(Color.softBackground)
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddChild = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.championBlue)
                    }
                }
            }
            .sheet(isPresented: $showAddChild) {
                AddChildView()
            }
            .onAppear {
                if selectedChild == nil {
                    selectedChild = dataService.children.first
                }
            }
        }
    }

    // MARK: - View Components

    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back!")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                Text(authService.currentUser?.displayName ?? "Champion")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }

            Spacer()

            // Today's date
            VStack(alignment: .trailing, spacing: 2) {
                Text(todayFormatted)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text(dayOfWeek)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    private var childSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(dataService.children) { child in
                    ChildSelectionCard(
                        child: child,
                        isSelected: selectedChild?.id == child.id,
                        onTap: { selectedChild = child }
                    )
                }
            }
        }
    }

    private func quickStatsSection(for child: Child) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(child.firstName)'s Stats")
                .font(.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: 12) {
                StatCard(
                    title: "Points",
                    value: "\(child.totalPoints)",
                    icon: "star.fill",
                    color: .victoryGold
                )

                StatCard(
                    title: "Level",
                    value: "\(child.currentLevel)",
                    icon: "trophy.fill",
                    color: .accentPurple
                )

                StatCard(
                    title: "Goals",
                    value: "\(dataService.getActiveGoals(for: child.id).count)",
                    icon: "target",
                    color: .championBlue
                )
            }
        }
    }

    private var upcomingActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Activities")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                NavigationLink(destination: ScheduleView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.championBlue)
                }
            }

            let upcoming = dataService.getUpcomingClasses(limit: 3)

            if upcoming.isEmpty {
                EmptyStateCard(
                    icon: "calendar",
                    title: "No upcoming activities",
                    subtitle: "Add sports and schedule activities"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(upcoming) { sportClass in
                        let sport = dataService.sports.first { $0.id == sportClass.sportId }
                        let child = dataService.getChild(id: sportClass.childId)

                        UpcomingActivityRow(
                            sportClass: sportClass,
                            sport: sport,
                            child: child
                        )
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
            }
        }
    }

    private func activeGoalsSection(for child: Child) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Goals")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                NavigationLink(destination: GoalsView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.championBlue)
                }
            }

            let goals = dataService.getActiveGoals(for: child.id).prefix(3)

            if goals.isEmpty {
                EmptyStateCard(
                    icon: "target",
                    title: "No active goals",
                    subtitle: "Set goals to track progress"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(goals)) { goal in
                        CompactGoalCard(goal: goal)
                    }
                }
            }
        }
    }

    private var conflictsSection: some View {
        let conflicts = dataService.detectConflicts(for: Date())

        return Group {
            if !conflicts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.warning)
                        Text("Needs Attention")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                    }

                    VStack(spacing: 8) {
                        ForEach(conflicts) { conflict in
                            ConflictRow(conflict: conflict)
                        }
                    }
                    .padding()
                    .background(Color.warning.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Formatters

    private var todayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.textSecondary.opacity(0.5))

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.white)
        .cornerRadius(16)
    }
}

struct ConflictRow: View {
    let conflict: ScheduleConflict

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: conflict.type.iconName)
                .foregroundColor(.warning)

            Text(conflict.description)
                .font(.subheadline)
                .foregroundColor(.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService())
        .environmentObject(DataService())
}
