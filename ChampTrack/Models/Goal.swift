import Foundation

enum GoalType: String, Codable, CaseIterable {
    case sports = "sports"
    case nutrition = "nutrition"
    case attendance = "attendance"
    case personal = "personal"

    var displayName: String {
        switch self {
        case .sports: return "Sports"
        case .nutrition: return "Nutrition"
        case .attendance: return "Attendance"
        case .personal: return "Personal"
        }
    }

    var iconName: String {
        switch self {
        case .sports: return "sportscourt.fill"
        case .nutrition: return "leaf.fill"
        case .attendance: return "calendar.badge.checkmark"
        case .personal: return "star.fill"
        }
    }
}

enum GoalStatus: String, Codable {
    case active = "active"
    case completed = "completed"
    case archived = "archived"

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }
}

enum GoalPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var colorHex: String {
        switch self {
        case .low: return "7F8C8D"
        case .medium: return "F39C12"
        case .high: return "E74C3C"
        }
    }
}

enum GoalDuration: String, Codable, CaseIterable {
    case shortTerm = "shortTerm"
    case mediumTerm = "mediumTerm"
    case longTerm = "longTerm"

    var displayName: String {
        switch self {
        case .shortTerm: return "Short-term (1-4 weeks)"
        case .mediumTerm: return "Medium-term (1-3 months)"
        case .longTerm: return "Long-term (3+ months)"
        }
    }
}

struct Goal: Identifiable, Codable {
    let id: String
    var childId: String
    var familyId: String
    var type: GoalType
    var title: String
    var description: String?
    var targetValue: Double
    var currentValue: Double
    var unit: String
    var startDate: Date
    var endDate: Date
    var status: GoalStatus
    var priority: GoalPriority
    var relatedSportId: String?
    var parentNotes: String?
    var childNotes: String?
    var milestones: [Milestone]
    var pointsReward: Int
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        childId: String,
        familyId: String,
        type: GoalType,
        title: String,
        description: String? = nil,
        targetValue: Double,
        currentValue: Double = 0,
        unit: String,
        startDate: Date = Date(),
        endDate: Date,
        status: GoalStatus = .active,
        priority: GoalPriority = .medium,
        relatedSportId: String? = nil,
        parentNotes: String? = nil,
        childNotes: String? = nil,
        milestones: [Milestone] = [],
        pointsReward: Int = 100,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.childId = childId
        self.familyId = familyId
        self.type = type
        self.title = title
        self.description = description
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.priority = priority
        self.relatedSportId = relatedSportId
        self.parentNotes = parentNotes
        self.childNotes = childNotes
        self.milestones = milestones
        self.pointsReward = pointsReward
        self.createdAt = createdAt
    }

    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(100, (currentValue / targetValue) * 100)
    }

    var isComplete: Bool {
        currentValue >= targetValue
    }

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }

    var isOverdue: Bool {
        Date() > endDate && status == .active
    }
}

struct Milestone: Identifiable, Codable {
    let id: String
    var title: String
    var targetValue: Double
    var isCompleted: Bool
    var completedAt: Date?

    init(
        id: String = UUID().uuidString,
        title: String,
        targetValue: Double,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.targetValue = targetValue
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}
