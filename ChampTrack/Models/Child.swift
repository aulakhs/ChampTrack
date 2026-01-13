import Foundation

enum Gender: String, Codable, CaseIterable {
    case male = "male"
    case female = "female"
    case other = "other"

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        }
    }
}

struct Child: Identifiable, Codable, Hashable {
    let id: String
    var familyId: String
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var gender: Gender
    var weight: Double // in kg
    var height: Double // in cm
    var photoURL: String?
    var allergies: [String]
    var medicalConditions: [String]
    var emergencyContact: String?
    var schoolGrade: String?
    var totalPoints: Int
    var currentLevel: Int
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        familyId: String,
        firstName: String,
        lastName: String,
        dateOfBirth: Date,
        gender: Gender,
        weight: Double,
        height: Double,
        photoURL: String? = nil,
        allergies: [String] = [],
        medicalConditions: [String] = [],
        emergencyContact: String? = nil,
        schoolGrade: String? = nil,
        totalPoints: Int = 0,
        currentLevel: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.familyId = familyId
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.weight = weight
        self.height = height
        self.photoURL = photoURL
        self.allergies = allergies
        self.medicalConditions = medicalConditions
        self.emergencyContact = emergencyContact
        self.schoolGrade = schoolGrade
        self.totalPoints = totalPoints
        self.currentLevel = currentLevel
        self.createdAt = createdAt
    }

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    var levelTitle: String {
        switch currentLevel {
        case 1...5: return "Rookie"
        case 6...10: return "Rising Star"
        case 11...20: return "Champion"
        default: return "Legend"
        }
    }

    var pointsToNextLevel: Int {
        let thresholds = [0, 100, 250, 500, 800, 1200, 1700, 2300, 3000, 3800, 4700, 5700, 6800, 8000, 9300, 10700, 12200, 13800, 15500, 17300]
        let nextLevel = min(currentLevel + 1, thresholds.count)
        let threshold = nextLevel < thresholds.count ? thresholds[nextLevel] : thresholds.last! + 2000
        return max(0, threshold - totalPoints)
    }
}
