import Foundation

enum AchievementType: String, Codable {
    case trophy = "trophy"
    case badge = "badge"

    var displayName: String {
        switch self {
        case .trophy: return "Trophy"
        case .badge: return "Badge"
        }
    }
}

enum AchievementTier: String, Codable, CaseIterable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"

    var displayName: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        }
    }

    var colorHex: String {
        switch self {
        case .bronze: return "CD7F32"
        case .silver: return "C0C0C0"
        case .gold: return "FFD700"
        }
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case sports = "sports"
    case nutrition = "nutrition"
    case streak = "streak"
    case milestone = "milestone"
    case special = "special"

    var displayName: String {
        switch self {
        case .sports: return "Sports"
        case .nutrition: return "Nutrition"
        case .streak: return "Streak"
        case .milestone: return "Milestone"
        case .special: return "Special"
        }
    }
}

struct Achievement: Identifiable, Codable {
    let id: String
    var childId: String
    var type: AchievementType
    var category: AchievementCategory
    var title: String
    var description: String
    var iconName: String
    var tier: AchievementTier
    var pointsAwarded: Int
    var earnedDate: Date?
    var relatedGoalId: String?
    var isUnlocked: Bool
    var progress: Double?
    var requirement: Double?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        childId: String,
        type: AchievementType,
        category: AchievementCategory,
        title: String,
        description: String,
        iconName: String,
        tier: AchievementTier,
        pointsAwarded: Int,
        earnedDate: Date? = nil,
        relatedGoalId: String? = nil,
        isUnlocked: Bool = false,
        progress: Double? = nil,
        requirement: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.childId = childId
        self.type = type
        self.category = category
        self.title = title
        self.description = description
        self.iconName = iconName
        self.tier = tier
        self.pointsAwarded = pointsAwarded
        self.earnedDate = earnedDate
        self.relatedGoalId = relatedGoalId
        self.isUnlocked = isUnlocked
        self.progress = progress
        self.requirement = requirement
        self.createdAt = createdAt
    }

    var progressPercentage: Double {
        guard let progress = progress, let requirement = requirement, requirement > 0 else {
            return isUnlocked ? 100 : 0
        }
        return min(100, (progress / requirement) * 100)
    }

    // Predefined achievement templates
    static var templates: [Achievement] {
        [
            // Sports achievements
            Achievement(
                childId: "",
                type: .badge,
                category: .sports,
                title: "First Goal",
                description: "Complete your first sports goal",
                iconName: "star.fill",
                tier: .bronze,
                pointsAwarded: 50,
                requirement: 1
            ),
            Achievement(
                childId: "",
                type: .trophy,
                category: .sports,
                title: "Perfect Attendance",
                description: "Attend all sessions in a month",
                iconName: "calendar.badge.checkmark",
                tier: .gold,
                pointsAwarded: 200,
                requirement: 1
            ),

            // Streak achievements
            Achievement(
                childId: "",
                type: .badge,
                category: .streak,
                title: "Week Warrior",
                description: "Complete a 7-day streak",
                iconName: "flame.fill",
                tier: .bronze,
                pointsAwarded: 50,
                requirement: 7
            ),
            Achievement(
                childId: "",
                type: .badge,
                category: .streak,
                title: "Month Master",
                description: "Complete a 30-day streak",
                iconName: "flame.fill",
                tier: .gold,
                pointsAwarded: 200,
                requirement: 30
            ),

            // Nutrition achievements
            Achievement(
                childId: "",
                type: .badge,
                category: .nutrition,
                title: "Nutrition Ninja",
                description: "Meet nutrition goals for 7 days",
                iconName: "leaf.fill",
                tier: .silver,
                pointsAwarded: 100,
                requirement: 7
            ),
            Achievement(
                childId: "",
                type: .trophy,
                category: .nutrition,
                title: "Hydration Hero",
                description: "Meet hydration goals for 14 days",
                iconName: "drop.fill",
                tier: .silver,
                pointsAwarded: 150,
                requirement: 14
            ),

            // Milestone achievements
            Achievement(
                childId: "",
                type: .badge,
                category: .milestone,
                title: "Century Club",
                description: "Earn 100 points",
                iconName: "100.circle.fill",
                tier: .bronze,
                pointsAwarded: 25,
                requirement: 100
            ),
            Achievement(
                childId: "",
                type: .trophy,
                category: .milestone,
                title: "Goal Crusher",
                description: "Complete 10 goals",
                iconName: "target",
                tier: .gold,
                pointsAwarded: 300,
                requirement: 10
            )
        ]
    }
}
