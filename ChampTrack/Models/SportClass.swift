import Foundation

enum ClassType: String, Codable, CaseIterable {
    case practice = "practice"
    case game = "game"
    case tournament = "tournament"
    case training = "training"

    var displayName: String {
        switch self {
        case .practice: return "Practice"
        case .game: return "Game"
        case .tournament: return "Tournament"
        case .training: return "Training"
        }
    }

    var iconName: String {
        switch self {
        case .practice: return "figure.run"
        case .game: return "trophy.fill"
        case .tournament: return "star.fill"
        case .training: return "dumbbell.fill"
        }
    }

    var points: Int {
        switch self {
        case .practice: return 10
        case .game: return 20
        case .tournament: return 30
        case .training: return 15
        }
    }
}

enum ClassStatus: String, Codable {
    case scheduled = "scheduled"
    case completed = "completed"
    case cancelled = "cancelled"
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case none = "none"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .none: return "One-time"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        }
    }
}

struct Location: Codable {
    var name: String
    var address: String?
    var latitude: Double?
    var longitude: Double?

    init(name: String, address: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct SportClass: Identifiable, Codable {
    let id: String
    var sportId: String
    var childId: String
    var familyId: String
    var type: ClassType
    var dateTime: Date
    var duration: Int // in minutes
    var location: Location?
    var recurringFrequency: RecurringFrequency
    var recurringUntil: Date?
    var dropoffAssignedTo: String?
    var pickupAssignedTo: String?
    var notes: String?
    var equipmentNeeded: [String]
    var status: ClassStatus
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        sportId: String,
        childId: String,
        familyId: String,
        type: ClassType,
        dateTime: Date,
        duration: Int = 60,
        location: Location? = nil,
        recurringFrequency: RecurringFrequency = .none,
        recurringUntil: Date? = nil,
        dropoffAssignedTo: String? = nil,
        pickupAssignedTo: String? = nil,
        notes: String? = nil,
        equipmentNeeded: [String] = [],
        status: ClassStatus = .scheduled,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sportId = sportId
        self.childId = childId
        self.familyId = familyId
        self.type = type
        self.dateTime = dateTime
        self.duration = duration
        self.location = location
        self.recurringFrequency = recurringFrequency
        self.recurringUntil = recurringUntil
        self.dropoffAssignedTo = dropoffAssignedTo
        self.pickupAssignedTo = pickupAssignedTo
        self.notes = notes
        self.equipmentNeeded = equipmentNeeded
        self.status = status
        self.createdAt = createdAt
    }

    var endTime: Date {
        Calendar.current.date(byAdding: .minute, value: duration, to: dateTime) ?? dateTime
    }

    var assignmentStatus: AssignmentStatus {
        if dropoffAssignedTo != nil && pickupAssignedTo != nil {
            return .fullyAssigned
        } else if dropoffAssignedTo != nil || pickupAssignedTo != nil {
            return .partiallyAssigned
        }
        return .unassigned
    }

    enum AssignmentStatus {
        case fullyAssigned
        case partiallyAssigned
        case unassigned

        var icon: String {
            switch self {
            case .fullyAssigned: return "checkmark.circle.fill"
            case .partiallyAssigned: return "exclamationmark.circle.fill"
            case .unassigned: return "xmark.circle.fill"
            }
        }

        var description: String {
            switch self {
            case .fullyAssigned: return "Assigned"
            case .partiallyAssigned: return "Partial"
            case .unassigned: return "Unassigned"
            }
        }
    }
}
