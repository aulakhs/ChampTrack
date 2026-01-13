import Foundation

enum UserRole: String, Codable, CaseIterable {
    case parent = "parent"
    case child = "child"
    case observer = "observer"

    var displayName: String {
        switch self {
        case .parent: return "Parent"
        case .child: return "Child"
        case .observer: return "Observer"
        }
    }
}

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var displayName: String
    var role: UserRole
    var familyId: String?
    var photoURL: String?
    var notificationPreferences: NotificationPreferences
    var createdAt: Date
    var lastLoginAt: Date

    init(
        id: String = UUID().uuidString,
        email: String,
        displayName: String,
        role: UserRole = .parent,
        familyId: String? = nil,
        photoURL: String? = nil,
        notificationPreferences: NotificationPreferences = NotificationPreferences(),
        createdAt: Date = Date(),
        lastLoginAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.familyId = familyId
        self.photoURL = photoURL
        self.notificationPreferences = notificationPreferences
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }
}

struct NotificationPreferences: Codable {
    var pushEnabled: Bool
    var emailEnabled: Bool
    var smsEnabled: Bool
    var scheduleReminders: Bool
    var nutritionReminders: Bool
    var achievementAlerts: Bool
    var reminderMinutesBefore: Int
    var quietHoursStart: Int?
    var quietHoursEnd: Int?

    init(
        pushEnabled: Bool = true,
        emailEnabled: Bool = true,
        smsEnabled: Bool = false,
        scheduleReminders: Bool = true,
        nutritionReminders: Bool = true,
        achievementAlerts: Bool = true,
        reminderMinutesBefore: Int = 30,
        quietHoursStart: Int? = nil,
        quietHoursEnd: Int? = nil
    ) {
        self.pushEnabled = pushEnabled
        self.emailEnabled = emailEnabled
        self.smsEnabled = smsEnabled
        self.scheduleReminders = scheduleReminders
        self.nutritionReminders = nutritionReminders
        self.achievementAlerts = achievementAlerts
        self.reminderMinutesBefore = reminderMinutesBefore
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
    }
}
