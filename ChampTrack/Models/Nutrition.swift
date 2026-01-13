import Foundation

enum MealType: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"

    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }

    var iconName: String {
        switch self {
        case .breakfast: return "sun.horizon.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "carrot.fill"
        }
    }

    var defaultTime: (hour: Int, minute: Int) {
        switch self {
        case .breakfast: return (8, 0)
        case .lunch: return (12, 0)
        case .dinner: return (18, 0)
        case .snack: return (15, 0)
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "sedentary"
    case moderate = "moderate"
    case active = "active"
    case veryActive = "veryActive"

    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary (0-2 activities/week)"
        case .moderate: return "Moderate (3-4 activities/week)"
        case .active: return "Active (5-6 activities/week)"
        case .veryActive: return "Very Active (7+ activities/week)"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .moderate: return 1.375
        case .active: return 1.55
        case .veryActive: return 1.725
        }
    }
}

struct FoodItem: Identifiable, Codable {
    let id: String
    var name: String
    var calories: Double
    var protein: Double // grams
    var carbs: Double // grams
    var fats: Double // grams
    var portion: String
    var portionGrams: Double?

    init(
        id: String = UUID().uuidString,
        name: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fats: Double,
        portion: String = "1 serving",
        portionGrams: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.portion = portion
        self.portionGrams = portionGrams
    }
}

struct Meal: Identifiable, Codable {
    let id: String
    var childId: String
    var date: Date
    var mealType: MealType
    var photoURLs: [String]
    var foods: [FoodItem]
    var notes: String?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        childId: String,
        date: Date = Date(),
        mealType: MealType,
        photoURLs: [String] = [],
        foods: [FoodItem] = [],
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.childId = childId
        self.date = date
        self.mealType = mealType
        self.photoURLs = photoURLs
        self.foods = foods
        self.notes = notes
        self.createdAt = createdAt
    }

    var totalCalories: Double {
        foods.reduce(0) { $0 + $1.calories }
    }

    var totalProtein: Double {
        foods.reduce(0) { $0 + $1.protein }
    }

    var totalCarbs: Double {
        foods.reduce(0) { $0 + $1.carbs }
    }

    var totalFats: Double {
        foods.reduce(0) { $0 + $1.fats }
    }
}

struct NutritionTarget: Identifiable, Codable {
    let id: String
    var childId: String
    var date: Date
    var calories: Double
    var protein: Double
    var carbs: Double
    var fats: Double
    var hydration: Double // in ml
    var isAutoCalculated: Bool
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        childId: String,
        date: Date = Date(),
        calories: Double,
        protein: Double,
        carbs: Double,
        fats: Double,
        hydration: Double,
        isAutoCalculated: Bool = true,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.childId = childId
        self.date = date
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.hydration = hydration
        self.isAutoCalculated = isAutoCalculated
        self.updatedAt = updatedAt
    }

    static func calculate(for child: Child, activityLevel: ActivityLevel) -> NutritionTarget {
        let age = child.age
        let weightKg = child.weight
        let heightCm = child.height
        let isMale = child.gender == .male

        // Harris-Benedict BMR calculation for children (simplified)
        var bmr: Double
        if isMale {
            bmr = 88.362 + (13.397 * weightKg) + (4.799 * heightCm) - (5.677 * Double(age))
        } else {
            bmr = 447.593 + (9.247 * weightKg) + (3.098 * heightCm) - (4.330 * Double(age))
        }

        // Adjust for age (children have higher metabolic needs)
        if age < 10 {
            bmr *= 1.1
        } else if age < 14 {
            bmr *= 1.05
        }

        let dailyCalories = bmr * activityLevel.multiplier

        // Macronutrient distribution
        let protein = weightKg * 1.2 // 1.2g per kg for active children
        let fats = (dailyCalories * 0.30) / 9 // 30% calories from fat
        let carbs = (dailyCalories * 0.50) / 4 // 50% calories from carbs

        // Hydration: ~30-40ml per kg body weight
        let hydration = weightKg * 35

        return NutritionTarget(
            childId: child.id,
            calories: dailyCalories,
            protein: protein,
            carbs: carbs,
            fats: fats,
            hydration: hydration
        )
    }
}
