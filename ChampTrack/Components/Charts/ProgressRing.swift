import SwiftUI

struct ProgressRing: View {
    let progress: Double // 0 to 1
    var lineWidth: CGFloat = 8
    var size: CGFloat = 60
    var color: Color = .championBlue
    var backgroundColor: Color = .gray.opacity(0.2)
    var showPercentage: Bool = true

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Percentage text
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.22, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
        }
    }
}

struct MacroProgressBar: View {
    let label: String
    let current: Double
    let target: Double
    let unit: String
    var color: Color = .championBlue

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    private var statusColor: Color {
        if progress >= 0.9 { return .success }
        if progress >= 0.7 { return .warning }
        return color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("\(Int(current))/\(Int(target)) \(unit)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

struct NutritionProgressCard: View {
    let calories: (current: Double, target: Double)
    let protein: (current: Double, target: Double)
    let carbs: (current: Double, target: Double)
    let fats: (current: Double, target: Double)

    var body: some View {
        VStack(spacing: 16) {
            // Main calorie ring
            HStack(spacing: 24) {
                ProgressRing(
                    progress: calories.target > 0 ? calories.current / calories.target : 0,
                    lineWidth: 10,
                    size: 80,
                    color: calorieColor
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Calories")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Text("\(Int(calories.current)) / \(Int(calories.target)) kcal")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    Text(calorieStatus)
                        .font(.caption)
                        .foregroundColor(calorieColor)
                }

                Spacer()
            }

            Divider()

            // Macro bars
            VStack(spacing: 12) {
                MacroProgressBar(
                    label: "Protein",
                    current: protein.current,
                    target: protein.target,
                    unit: "g",
                    color: .accentRed
                )

                MacroProgressBar(
                    label: "Carbs",
                    current: carbs.current,
                    target: carbs.target,
                    unit: "g",
                    color: .victoryGold
                )

                MacroProgressBar(
                    label: "Fats",
                    current: fats.current,
                    target: fats.target,
                    unit: "g",
                    color: .accentPurple
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var calorieProgress: Double {
        guard calories.target > 0 else { return 0 }
        return calories.current / calories.target
    }

    private var calorieColor: Color {
        if calorieProgress >= 0.9 && calorieProgress <= 1.1 { return .success }
        if calorieProgress >= 0.7 { return .warning }
        return .championBlue
    }

    private var calorieStatus: String {
        if calorieProgress >= 0.9 && calorieProgress <= 1.1 { return "On track!" }
        if calorieProgress >= 0.7 { return "Almost there" }
        let remaining = Int(calories.target - calories.current)
        return "\(remaining) kcal to go"
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            ProgressRing(progress: 0.75)
            ProgressRing(progress: 0.45, color: .energyGreen)
            ProgressRing(progress: 1.0, color: .victoryGold)
        }

        MacroProgressBar(label: "Protein", current: 45, target: 60, unit: "g")

        NutritionProgressCard(
            calories: (current: 1450, target: 1800),
            protein: (current: 45, target: 60),
            carbs: (current: 180, target: 225),
            fats: (current: 50, target: 60)
        )
    }
    .padding()
    .background(Color.softBackground)
}
