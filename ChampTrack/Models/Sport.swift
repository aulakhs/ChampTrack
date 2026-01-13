import Foundation
import SwiftUI

struct Sport: Identifiable, Codable, Hashable {
    let id: String
    var childId: String
    var familyId: String
    var sportName: String
    var teamName: String?
    var coachName: String?
    var coachContact: String?
    var seasonStart: Date?
    var seasonEnd: Date?
    var location: String?
    var colorHex: String
    var iconName: String
    var isActive: Bool
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        childId: String,
        familyId: String,
        sportName: String,
        teamName: String? = nil,
        coachName: String? = nil,
        coachContact: String? = nil,
        seasonStart: Date? = nil,
        seasonEnd: Date? = nil,
        location: String? = nil,
        colorHex: String = "4A90E2",
        iconName: String = "sportscourt.fill",
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.childId = childId
        self.familyId = familyId
        self.sportName = sportName
        self.teamName = teamName
        self.coachName = coachName
        self.coachContact = coachContact
        self.seasonStart = seasonStart
        self.seasonEnd = seasonEnd
        self.location = location
        self.colorHex = colorHex
        self.iconName = iconName
        self.isActive = isActive
        self.createdAt = createdAt
    }

    var color: Color {
        Color(hex: colorHex)
    }

    static var sportIcons: [String: String] {
        [
            "Soccer": "soccerball",
            "Basketball": "basketball.fill",
            "Swimming": "figure.pool.swim",
            "Baseball": "baseball.fill",
            "Football": "football.fill",
            "Tennis": "tennis.racket",
            "Volleyball": "volleyball.fill",
            "Hockey": "hockey.puck.fill",
            "Golf": "figure.golf",
            "Gymnastics": "figure.gymnastics",
            "Track": "figure.run",
            "Dance": "figure.dance",
            "Martial Arts": "figure.martial.arts",
            "Cycling": "bicycle",
            "Other": "sportscourt.fill"
        ]
    }

    static var sportColors: [String: String] {
        [
            "Soccer": "7ED321",
            "Basketball": "F5A623",
            "Swimming": "4A90E2",
            "Baseball": "E74C3C",
            "Football": "8B4513",
            "Tennis": "9B59B6",
            "Volleyball": "3498DB",
            "Hockey": "2C3E50",
            "Golf": "27AE60",
            "Gymnastics": "E91E63",
            "Track": "FF5722",
            "Dance": "9C27B0",
            "Martial Arts": "795548",
            "Cycling": "607D8B",
            "Other": "4A90E2"
        ]
    }
}
