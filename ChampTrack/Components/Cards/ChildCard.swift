import SwiftUI

struct ChildCard: View {
    let child: Child
    var showStats: Bool = true
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ChildAvatar(child: child, size: 60)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(child.fullName)
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text("\(child.age) years old")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                if showStats {
                    HStack(spacing: 12) {
                        Label("\(child.totalPoints) pts", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.victoryGold)

                        Label(child.levelTitle, systemImage: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(.accentPurple)
                    }
                }
            }

            Spacer()

            // Level badge
            if showStats {
                VStack(spacing: 2) {
                    Text("Lvl")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                    Text("\(child.currentLevel)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.championBlue)
                }
                .padding(12)
                .background(Color.championBlue.opacity(0.1))
                .clipShape(Circle())
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct ChildAvatar: View {
    let child: Child
    var size: CGFloat = 50
    var showBadge: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let photoURL = child.photoURL, !photoURL.isEmpty {
                // In production, load actual image
                Circle()
                    .fill(avatarColor)
                    .frame(width: size, height: size)
                    .overlay(
                        Text(child.firstName.prefix(1))
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundColor(.white)
                    )
            } else {
                Circle()
                    .fill(avatarColor)
                    .frame(width: size, height: size)
                    .overlay(
                        Text(child.firstName.prefix(1))
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }

            if showBadge {
                Circle()
                    .fill(Color.energyGreen)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: size * 0.15, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 2, y: 2)
            }
        }
    }

    private var avatarColor: Color {
        switch child.gender {
        case .female: return .accentPurple
        case .male: return .championBlue
        case .other: return .energyGreen
        }
    }
}

struct ChildSelectionCard: View {
    let child: Child
    var isSelected: Bool = false
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ChildAvatar(child: child, size: 44, showBadge: isSelected)

                VStack(alignment: .leading, spacing: 2) {
                    Text(child.firstName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    Text("\(child.age) yrs")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.championBlue.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.championBlue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let mockChild = Child(
        familyId: "1",
        firstName: "Emma",
        lastName: "Smith",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -10, to: Date())!,
        gender: .female,
        weight: 32,
        height: 140,
        totalPoints: 350,
        currentLevel: 4
    )

    VStack(spacing: 20) {
        ChildCard(child: mockChild)
        ChildCard(child: mockChild, showStats: false, showChevron: false)

        HStack {
            ChildSelectionCard(child: mockChild, isSelected: true, onTap: {})
            ChildSelectionCard(child: mockChild, isSelected: false, onTap: {})
        }
    }
    .padding()
    .background(Color.softBackground)
}
