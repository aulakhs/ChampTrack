import SwiftUI

struct GoalCard: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: goal.type.iconName)
                        .foregroundColor(typeColor)
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                        .background(typeColor.opacity(0.2))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)

                        Text(goal.type.displayName)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    // Priority indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: goal.priority.colorHex))
                            .frame(width: 8, height: 8)
                        Text(goal.priority.displayName)
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                }

                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressColor)
                                .frame(width: geometry.size.width * (goal.progressPercentage / 100), height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(Int(goal.currentValue))/\(Int(goal.targetValue)) \(goal.unit)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Text("\(Int(goal.progressPercentage))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(progressColor)
                    }
                }

                // Footer
                HStack {
                    if goal.isOverdue {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.accentRed)
                    } else {
                        Label("\(goal.daysRemaining) days left", systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Label("\(goal.pointsReward) pts", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.victoryGold)
                }
            }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var typeColor: Color {
        switch goal.type {
        case .sports: return .championBlue
        case .nutrition: return .energyGreen
        case .attendance: return .victoryGold
        case .personal: return .accentPurple
        }
    }

    private var progressColor: Color {
        if goal.isComplete { return .success }
        if goal.progressPercentage >= 70 { return .warning }
        return .championBlue
    }
}

struct CompactGoalCard: View {
    let goal: Goal

    var body: some View {
        HStack(spacing: 12) {
                // Progress ring
                ProgressRing(
                    progress: goal.progressPercentage / 100,
                    lineWidth: 4,
                    size: 40,
                    color: typeColor,
                    showPercentage: false
                )

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    Text("\(Int(goal.currentValue))/\(Int(goal.targetValue)) \(goal.unit)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Percentage
                Text("\(Int(goal.progressPercentage))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(typeColor)
            }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    private var typeColor: Color {
        switch goal.type {
        case .sports: return .championBlue
        case .nutrition: return .energyGreen
        case .attendance: return .victoryGold
        case .personal: return .accentPurple
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 8) {
            // Trophy/Badge icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ?
                          Color(hex: achievement.tier.colorHex).opacity(0.2) :
                          Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isUnlocked ?
                                     Color(hex: achievement.tier.colorHex) :
                                     Color.gray.opacity(0.4))
            }

            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(achievement.isUnlocked ? .textPrimary : .textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if !achievement.isUnlocked {
                // Progress indicator
                if let progress = achievement.progress, let requirement = achievement.requirement {
                    Text("\(Int(progress))/\(Int(requirement))")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            } else {
                // Tier badge
                Text(achievement.tier.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: achievement.tier.colorHex))
            }
        }
        .frame(width: 90)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        .opacity(achievement.isUnlocked ? 1 : 0.7)
    }
}

#Preview {
    let mockGoal = Goal(
        childId: "1",
        familyId: "1",
        type: .sports,
        title: "Score 5 Goals",
        description: "Score 5 goals this season",
        targetValue: 5,
        currentValue: 3,
        unit: "goals",
        endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
        priority: .high,
        pointsReward: 150
    )

    let mockAchievement = Achievement(
        childId: "1",
        type: .trophy,
        category: .sports,
        title: "First Goal",
        description: "Complete your first goal",
        iconName: "star.fill",
        tier: .gold,
        pointsAwarded: 100,
        isUnlocked: true
    )

    VStack(spacing: 20) {
        GoalCard(goal: mockGoal)
        CompactGoalCard(goal: mockGoal)

        HStack {
            AchievementCard(achievement: mockAchievement)
            AchievementCard(achievement: Achievement(
                childId: "1",
                type: .badge,
                category: .streak,
                title: "Week Warrior",
                description: "7-day streak",
                iconName: "flame.fill",
                tier: .bronze,
                pointsAwarded: 50,
                progress: 4,
                requirement: 7
            ))
        }
    }
    .padding()
    .background(Color.softBackground)
}
