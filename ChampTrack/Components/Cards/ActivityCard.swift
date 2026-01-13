import SwiftUI

struct ActivityCard: View {
    let sportClass: SportClass
    let sport: Sport?
    let child: Child?
    var onTap: (() -> Void)? = nil

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Color bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(sport?.color ?? .championBlue)
                    .frame(width: 4)

                // Time
                VStack(spacing: 2) {
                    Text(dateFormatter.string(from: sportClass.dateTime))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    Text("\(sportClass.duration) min")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(width: 65)

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: sport?.iconName ?? "sportscourt.fill")
                            .foregroundColor(sport?.color ?? .championBlue)
                            .font(.caption)

                        Text(sport?.sportName ?? "Activity")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)

                        Text("(\(sportClass.type.displayName))")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    if let child = child {
                        Text(child.firstName)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    if let location = sportClass.location {
                        Label(location.name, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                // Assignment status
                VStack(spacing: 4) {
                    Image(systemName: sportClass.assignmentStatus.icon)
                        .foregroundColor(assignmentColor)
                        .font(.system(size: 20))

                    Text(sportClass.assignmentStatus.description)
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var assignmentColor: Color {
        switch sportClass.assignmentStatus {
        case .fullyAssigned: return .success
        case .partiallyAssigned: return .warning
        case .unassigned: return .accentRed
        }
    }
}

struct CompactActivityCard: View {
    let sportClass: SportClass
    let sport: Sport?

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(sport?.color ?? .championBlue)
                .frame(width: 8, height: 8)

            Text(timeFormatter.string(from: sportClass.dateTime))
                .font(.caption)
                .foregroundColor(.textSecondary)
                .frame(width: 55, alignment: .leading)

            Text(sport?.sportName ?? "Activity")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)

            Spacer()

            Text(sportClass.type.displayName)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(sport?.color.opacity(0.2) ?? Color.championBlue.opacity(0.2))
                .foregroundColor(sport?.color ?? .championBlue)
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

struct UpcomingActivityRow: View {
    let sportClass: SportClass
    let sport: Sport?
    let child: Child?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            // Sport icon
            ZStack {
                Circle()
                    .fill(sport?.color.opacity(0.2) ?? Color.championBlue.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: sport?.iconName ?? "sportscourt.fill")
                    .foregroundColor(sport?.color ?? .championBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(sport?.sportName ?? "Activity")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)

                    if let child = child {
                        Text("- \(child.firstName)")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }

                HStack(spacing: 8) {
                    Text(dateFormatter.string(from: sportClass.dateTime))
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    Text(timeFormatter.string(from: sportClass.dateTime))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            // Type badge
            Text(sportClass.type.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(typeColor.opacity(0.2))
                .foregroundColor(typeColor)
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }

    private var typeColor: Color {
        switch sportClass.type {
        case .game: return .victoryGold
        case .practice: return .championBlue
        case .tournament: return .accentPurple
        case .training: return .energyGreen
        }
    }
}

#Preview {
    let mockSport = Sport(
        childId: "1",
        familyId: "1",
        sportName: "Soccer",
        teamName: "Lightning",
        colorHex: "7ED321",
        iconName: "soccerball"
    )

    let mockClass = SportClass(
        sportId: mockSport.id,
        childId: "1",
        familyId: "1",
        type: .practice,
        dateTime: Date(),
        duration: 90,
        location: Location(name: "City Sports Complex"),
        dropoffAssignedTo: "user1"
    )

    let mockChild = Child(
        familyId: "1",
        firstName: "Emma",
        lastName: "Smith",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -10, to: Date())!,
        gender: .female,
        weight: 32,
        height: 140
    )

    VStack(spacing: 16) {
        ActivityCard(sportClass: mockClass, sport: mockSport, child: mockChild)
        CompactActivityCard(sportClass: mockClass, sport: mockSport)
        UpcomingActivityRow(sportClass: mockClass, sport: mockSport, child: mockChild)
    }
    .padding()
    .background(Color.softBackground)
}
