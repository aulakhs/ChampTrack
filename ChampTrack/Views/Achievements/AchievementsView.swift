import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var dataService: DataService
    @State private var selectedChild: Child?
    @State private var selectedCategory: AchievementCategory? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Child selector
                if !dataService.children.isEmpty {
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
                        .padding()
                    }
                }

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            onTap: { selectedCategory = nil }
                        )

                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                onTap: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // Content
                ScrollView {
                    if let child = selectedChild ?? dataService.children.first {
                        achievementsContent(for: child)
                    } else {
                        EmptyStateCard(
                            icon: "trophy.fill",
                            title: "No children added",
                            subtitle: "Add a child to view achievements"
                        )
                        .padding()
                    }
                }
            }
            .background(Color.softBackground)
            .navigationTitle("Achievements")
            .onAppear {
                if selectedChild == nil {
                    selectedChild = dataService.children.first
                }
            }
        }
    }

    @ViewBuilder
    private func achievementsContent(for child: Child) -> some View {
        VStack(spacing: 20) {
            // Points and level summary
            pointsSummary(for: child)

            // Trophy case
            let achievements = filteredAchievements(for: child)
            let unlocked = achievements.filter { $0.isUnlocked }
            let locked = achievements.filter { !$0.isUnlocked }

            // Unlocked achievements
            if !unlocked.isEmpty {
                achievementSection(
                    title: "Earned Achievements",
                    count: unlocked.count,
                    achievements: unlocked
                )
            }

            // In progress
            let inProgress = locked.filter { $0.progress != nil && $0.progress! > 0 }
            if !inProgress.isEmpty {
                achievementSection(
                    title: "In Progress",
                    count: inProgress.count,
                    achievements: inProgress
                )
            }

            // Locked
            let notStarted = locked.filter { $0.progress == nil || $0.progress == 0 }
            if !notStarted.isEmpty {
                achievementSection(
                    title: "Locked",
                    count: notStarted.count,
                    achievements: notStarted
                )
            }
        }
        .padding()
    }

    private func pointsSummary(for child: Child) -> some View {
        VStack(spacing: 16) {
            // Level display
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.victoryGold.opacity(0.3), lineWidth: 8)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: levelProgress(for: child))
                        .stroke(Color.victoryGold, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(child.currentLevel)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.victoryGold)
                        Text(child.levelTitle)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Text("\(child.totalPoints) Total Points")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text("\(child.pointsToNextLevel) points to Level \(child.currentLevel + 1)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            // Quick stats
            HStack(spacing: 16) {
                let allAchievements = dataService.getAchievements(for: child.id)
                let unlocked = allAchievements.filter { $0.isUnlocked }

                AchievementStatPill(
                    icon: "trophy.fill",
                    value: "\(unlocked.filter { $0.type == .trophy }.count)",
                    label: "Trophies",
                    color: .victoryGold
                )

                AchievementStatPill(
                    icon: "rosette",
                    value: "\(unlocked.filter { $0.type == .badge }.count)",
                    label: "Badges",
                    color: .championBlue
                )

                AchievementStatPill(
                    icon: "flame.fill",
                    value: "0", // Would track streaks
                    label: "Streaks",
                    color: .accentRed
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    private func achievementSection(title: String, count: Int, achievements: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                Text("\(count)")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 90))
            ], spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
        }
    }

    private func filteredAchievements(for child: Child) -> [Achievement] {
        var achievements = dataService.getAchievements(for: child.id)

        if let category = selectedCategory {
            achievements = achievements.filter { $0.category == category }
        }

        return achievements
    }

    private func levelProgress(for child: Child) -> Double {
        let thresholds = [0, 100, 250, 500, 800, 1200, 1700, 2300, 3000, 3800, 4700, 5700, 6800, 8000, 9300, 10700, 12200, 13800, 15500, 17300]
        let currentLevel = child.currentLevel
        let points = child.totalPoints

        let currentThreshold = currentLevel <= thresholds.count ? thresholds[currentLevel - 1] : thresholds.last!
        let nextThreshold = currentLevel < thresholds.count ? thresholds[currentLevel] : currentThreshold + 2000

        let progressInLevel = Double(points - currentThreshold)
        let levelRange = Double(nextThreshold - currentThreshold)

        return min(1.0, progressInLevel / levelRange)
    }
}

struct AchievementStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    AchievementsView()
        .environmentObject(DataService())
}
