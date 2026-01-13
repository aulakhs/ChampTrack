import Foundation
import SwiftUI
import Combine

@MainActor
class DataService: ObservableObject {
    // MARK: - Published Properties
    @Published var family: Family?
    @Published var children: [Child] = []
    @Published var sports: [Sport] = []
    @Published var classes: [SportClass] = []
    @Published var meals: [Meal] = []
    @Published var goals: [Goal] = []
    @Published var achievements: [Achievement] = []
    @Published var nutritionTargets: [String: NutritionTarget] = [:] // childId -> target

    @Published var isLoading = false

    init() {
        loadMockData()
    }

    // MARK: - Family Management

    func createFamily(name: String, userId: String) {
        let family = Family(
            name: name,
            createdBy: userId,
            members: [userId]
        )
        self.family = family
    }

    // MARK: - Child Management

    func addChild(_ child: Child) {
        children.append(child)
        generateAchievementsForChild(child)
        calculateNutritionTarget(for: child)
    }

    func updateChild(_ child: Child) {
        if let index = children.firstIndex(where: { $0.id == child.id }) {
            children[index] = child
            calculateNutritionTarget(for: child)
        }
    }

    func deleteChild(id: String) {
        children.removeAll { $0.id == id }
        sports.removeAll { $0.childId == id }
        classes.removeAll { $0.childId == id }
        meals.removeAll { $0.childId == id }
        goals.removeAll { $0.childId == id }
        achievements.removeAll { $0.childId == id }
        nutritionTargets.removeValue(forKey: id)
    }

    func getChild(id: String) -> Child? {
        children.first { $0.id == id }
    }

    // MARK: - Sports Management

    func addSport(_ sport: Sport) {
        sports.append(sport)
    }

    func updateSport(_ sport: Sport) {
        if let index = sports.firstIndex(where: { $0.id == sport.id }) {
            sports[index] = sport
        }
    }

    func deleteSport(id: String) {
        sports.removeAll { $0.id == id }
        classes.removeAll { $0.sportId == id }
    }

    func getSports(for childId: String) -> [Sport] {
        sports.filter { $0.childId == childId }
    }

    // MARK: - Class Management

    func addClass(_ sportClass: SportClass) {
        classes.append(sportClass)
    }

    func updateClass(_ sportClass: SportClass) {
        if let index = classes.firstIndex(where: { $0.id == sportClass.id }) {
            classes[index] = sportClass
        }
    }

    func deleteClass(id: String) {
        classes.removeAll { $0.id == id }
    }

    func getClasses(for date: Date) -> [SportClass] {
        let calendar = Calendar.current
        return classes.filter { calendar.isDate($0.dateTime, inSameDayAs: date) }
    }

    func getClasses(for childId: String) -> [SportClass] {
        classes.filter { $0.childId == childId }
    }

    func getUpcomingClasses(limit: Int = 5) -> [SportClass] {
        let now = Date()
        return classes
            .filter { $0.dateTime > now && $0.status == .scheduled }
            .sorted { $0.dateTime < $1.dateTime }
            .prefix(limit)
            .map { $0 }
    }

    func assignTransportation(classId: String, dropoff: String?, pickup: String?) {
        if let index = classes.firstIndex(where: { $0.id == classId }) {
            classes[index].dropoffAssignedTo = dropoff
            classes[index].pickupAssignedTo = pickup
        }
    }

    func markClassComplete(id: String) {
        if let index = classes.firstIndex(where: { $0.id == id }) {
            classes[index].status = .completed
            let sportClass = classes[index]
            awardPointsForClass(sportClass)
        }
    }

    // MARK: - Nutrition Management

    func addMeal(_ meal: Meal) {
        meals.append(meal)
        checkNutritionGoals(for: meal.childId, on: meal.date)
    }

    func updateMeal(_ meal: Meal) {
        if let index = meals.firstIndex(where: { $0.id == meal.id }) {
            meals[index] = meal
        }
    }

    func deleteMeal(id: String) {
        meals.removeAll { $0.id == id }
    }

    func getMeals(for childId: String, on date: Date) -> [Meal] {
        let calendar = Calendar.current
        return meals.filter {
            $0.childId == childId && calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    func getDailyNutrition(for childId: String, on date: Date) -> (calories: Double, protein: Double, carbs: Double, fats: Double) {
        let dayMeals = getMeals(for: childId, on: date)
        return (
            calories: dayMeals.reduce(0) { $0 + $1.totalCalories },
            protein: dayMeals.reduce(0) { $0 + $1.totalProtein },
            carbs: dayMeals.reduce(0) { $0 + $1.totalCarbs },
            fats: dayMeals.reduce(0) { $0 + $1.totalFats }
        )
    }

    func calculateNutritionTarget(for child: Child) {
        let activitiesPerWeek = getClasses(for: child.id)
            .filter { $0.status == .scheduled }
            .count

        let activityLevel: ActivityLevel
        switch activitiesPerWeek {
        case 0...2: activityLevel = .sedentary
        case 3...4: activityLevel = .moderate
        case 5...6: activityLevel = .active
        default: activityLevel = .veryActive
        }

        let target = NutritionTarget.calculate(for: child, activityLevel: activityLevel)
        nutritionTargets[child.id] = target
    }

    // MARK: - Goals Management

    func addGoal(_ goal: Goal) {
        goals.append(goal)
    }

    func updateGoal(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        }
    }

    func deleteGoal(id: String) {
        goals.removeAll { $0.id == id }
    }

    func getGoals(for childId: String) -> [Goal] {
        goals.filter { $0.childId == childId }
    }

    func getActiveGoals(for childId: String) -> [Goal] {
        goals.filter { $0.childId == childId && $0.status == .active }
    }

    func completeGoal(id: String) {
        if let index = goals.firstIndex(where: { $0.id == id }) {
            goals[index].status = .completed
            goals[index].currentValue = goals[index].targetValue

            let goal = goals[index]
            awardPointsForGoal(goal)
        }
    }

    func updateGoalProgress(id: String, newValue: Double) {
        if let index = goals.firstIndex(where: { $0.id == id }) {
            goals[index].currentValue = newValue
            if goals[index].currentValue >= goals[index].targetValue {
                completeGoal(id: id)
            }
        }
    }

    // MARK: - Achievements Management

    func getAchievements(for childId: String) -> [Achievement] {
        achievements.filter { $0.childId == childId }
    }

    func getUnlockedAchievements(for childId: String) -> [Achievement] {
        achievements.filter { $0.childId == childId && $0.isUnlocked }
    }

    func unlockAchievement(id: String) {
        if let index = achievements.firstIndex(where: { $0.id == id }) {
            guard !achievements[index].isUnlocked else { return }

            achievements[index].isUnlocked = true
            achievements[index].earnedDate = Date()

            let achievement = achievements[index]
            awardPoints(to: achievement.childId, points: achievement.pointsAwarded)
        }
    }

    // MARK: - Points Management

    func awardPoints(to childId: String, points: Int) {
        if let index = children.firstIndex(where: { $0.id == childId }) {
            children[index].totalPoints += points
            updateLevel(for: childId)
            checkMilestoneAchievements(for: childId)
        }
    }

    private func updateLevel(for childId: String) {
        guard let index = children.firstIndex(where: { $0.id == childId }) else { return }

        let points = children[index].totalPoints
        let thresholds = [0, 100, 250, 500, 800, 1200, 1700, 2300, 3000, 3800, 4700, 5700, 6800, 8000, 9300, 10700, 12200, 13800, 15500, 17300]

        var newLevel = 1
        for (level, threshold) in thresholds.enumerated() {
            if points >= threshold {
                newLevel = level + 1
            }
        }

        children[index].currentLevel = newLevel
    }

    // MARK: - Private Methods

    private func awardPointsForClass(_ sportClass: SportClass) {
        awardPoints(to: sportClass.childId, points: sportClass.type.points)
    }

    private func awardPointsForGoal(_ goal: Goal) {
        awardPoints(to: goal.childId, points: goal.pointsReward)
    }

    private func checkNutritionGoals(for childId: String, on date: Date) {
        guard let target = nutritionTargets[childId] else { return }

        let daily = getDailyNutrition(for: childId, on: date)

        // Check if daily goals are met (within 10% tolerance)
        let caloriesMet = daily.calories >= target.calories * 0.9
        let proteinMet = daily.protein >= target.protein * 0.9

        if caloriesMet && proteinMet {
            // Award daily nutrition goal points
            awardPoints(to: childId, points: 15)
        }
    }

    private func checkMilestoneAchievements(for childId: String) {
        // Check point milestones
        if let child = getChild(id: childId) {
            if child.totalPoints >= 100 {
                if let achievement = achievements.first(where: { $0.childId == childId && $0.title == "Century Club" && !$0.isUnlocked }) {
                    unlockAchievement(id: achievement.id)
                }
            }
        }
    }

    private func generateAchievementsForChild(_ child: Child) {
        let templates = Achievement.templates
        for template in templates {
            var achievement = template
            achievement.childId = child.id
            achievements.append(achievement)
        }
    }

    // MARK: - Conflict Detection

    func detectConflicts(for date: Date) -> [ScheduleConflict] {
        var conflicts: [ScheduleConflict] = []
        let dayClasses = getClasses(for: date)

        // Check for child double-booking
        let childGroups = Dictionary(grouping: dayClasses, by: { $0.childId })
        for (childId, childClasses) in childGroups {
            let sorted = childClasses.sorted { $0.dateTime < $1.dateTime }
            for i in 0..<sorted.count - 1 {
                if sorted[i].endTime > sorted[i + 1].dateTime {
                    if let child = getChild(id: childId) {
                        conflicts.append(ScheduleConflict(
                            type: .childDoubleBooked,
                            description: "\(child.firstName) has overlapping activities",
                            classIds: [sorted[i].id, sorted[i + 1].id]
                        ))
                    }
                }
            }
        }

        // Check for unassigned transportation
        for sportClass in dayClasses {
            if sportClass.assignmentStatus == .unassigned {
                conflicts.append(ScheduleConflict(
                    type: .unassignedTransportation,
                    description: "Transportation not assigned",
                    classIds: [sportClass.id]
                ))
            }
        }

        return conflicts
    }

    // MARK: - Mock Data

    private func loadMockData() {
        // Create mock family
        let familyId = UUID().uuidString
        family = Family(
            id: familyId,
            name: "Smith Family",
            createdBy: "user1",
            members: ["user1", "user2"]
        )

        // Create mock children
        let child1 = Child(
            familyId: familyId,
            firstName: "Emma",
            lastName: "Smith",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -10, to: Date())!,
            gender: .female,
            weight: 32,
            height: 140,
            totalPoints: 350,
            currentLevel: 4
        )

        let child2 = Child(
            familyId: familyId,
            firstName: "Jake",
            lastName: "Smith",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -8, to: Date())!,
            gender: .male,
            weight: 28,
            height: 125,
            totalPoints: 180,
            currentLevel: 2
        )

        children = [child1, child2]

        // Generate achievements for children
        for child in children {
            generateAchievementsForChild(child)
            calculateNutritionTarget(for: child)
        }

        // Unlock some achievements for demo
        if let achievement = achievements.first(where: { $0.childId == child1.id && $0.title == "First Goal" }) {
            var updated = achievement
            updated.isUnlocked = true
            updated.earnedDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())
            if let index = achievements.firstIndex(where: { $0.id == achievement.id }) {
                achievements[index] = updated
            }
        }

        // Create mock sports
        let soccer = Sport(
            childId: child1.id,
            familyId: familyId,
            sportName: "Soccer",
            teamName: "Lightning Strikers",
            coachName: "Coach Williams",
            coachContact: "555-1234",
            location: "City Sports Complex",
            colorHex: Sport.sportColors["Soccer"]!,
            iconName: Sport.sportIcons["Soccer"]!
        )

        let swimming = Sport(
            childId: child1.id,
            familyId: familyId,
            sportName: "Swimming",
            teamName: "Dolphins Swim Club",
            coachName: "Coach Miller",
            location: "Community Pool",
            colorHex: Sport.sportColors["Swimming"]!,
            iconName: Sport.sportIcons["Swimming"]!
        )

        let basketball = Sport(
            childId: child2.id,
            familyId: familyId,
            sportName: "Basketball",
            teamName: "Junior Hawks",
            coachName: "Coach Johnson",
            location: "Elementary School Gym",
            colorHex: Sport.sportColors["Basketball"]!,
            iconName: Sport.sportIcons["Basketball"]!
        )

        sports = [soccer, swimming, basketball]

        // Create mock classes for the next week
        let calendar = Calendar.current
        var mockClasses: [SportClass] = []

        // Soccer practice tomorrow
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
            let practiceTime = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: tomorrow)!
            mockClasses.append(SportClass(
                sportId: soccer.id,
                childId: child1.id,
                familyId: familyId,
                type: .practice,
                dateTime: practiceTime,
                duration: 90,
                location: Location(name: "City Sports Complex", address: "123 Sports Ave"),
                dropoffAssignedTo: "user1",
                pickupAssignedTo: "user2"
            ))
        }

        // Swimming in 2 days
        if let dayAfter = calendar.date(byAdding: .day, value: 2, to: Date()) {
            let swimTime = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: dayAfter)!
            mockClasses.append(SportClass(
                sportId: swimming.id,
                childId: child1.id,
                familyId: familyId,
                type: .training,
                dateTime: swimTime,
                duration: 60,
                location: Location(name: "Community Pool", address: "456 Pool Lane"),
                dropoffAssignedTo: "user1"
            ))
        }

        // Basketball game in 3 days
        if let in3Days = calendar.date(byAdding: .day, value: 3, to: Date()) {
            let gameTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: in3Days)!
            mockClasses.append(SportClass(
                sportId: basketball.id,
                childId: child2.id,
                familyId: familyId,
                type: .game,
                dateTime: gameTime,
                duration: 60,
                location: Location(name: "Elementary School Gym", address: "789 School St")
            ))
        }

        classes = mockClasses

        // Create mock goals
        let goal1 = Goal(
            childId: child1.id,
            familyId: familyId,
            type: .sports,
            title: "Score 5 Goals",
            description: "Score 5 goals during soccer games this season",
            targetValue: 5,
            currentValue: 3,
            unit: "goals",
            endDate: calendar.date(byAdding: .month, value: 2, to: Date())!,
            priority: .high,
            relatedSportId: soccer.id,
            pointsReward: 150
        )

        let goal2 = Goal(
            childId: child1.id,
            familyId: familyId,
            type: .attendance,
            title: "Perfect Attendance",
            description: "Attend all swim practices this month",
            targetValue: 8,
            currentValue: 5,
            unit: "sessions",
            endDate: calendar.date(byAdding: .month, value: 1, to: Date())!,
            priority: .medium,
            relatedSportId: swimming.id,
            pointsReward: 100
        )

        let goal3 = Goal(
            childId: child2.id,
            familyId: familyId,
            type: .nutrition,
            title: "Hydration Hero",
            description: "Drink 6 glasses of water every day for a week",
            targetValue: 7,
            currentValue: 4,
            unit: "days",
            endDate: calendar.date(byAdding: .day, value: 10, to: Date())!,
            priority: .medium,
            pointsReward: 75
        )

        goals = [goal1, goal2, goal3]

        // Create mock meals for today
        let todayBreakfast = Meal(
            childId: child1.id,
            date: Date(),
            mealType: .breakfast,
            foods: [
                FoodItem(name: "Oatmeal", calories: 150, protein: 5, carbs: 27, fats: 3),
                FoodItem(name: "Banana", calories: 105, protein: 1, carbs: 27, fats: 0),
                FoodItem(name: "Milk", calories: 100, protein: 8, carbs: 12, fats: 2)
            ]
        )

        meals = [todayBreakfast]
    }
}

// MARK: - Schedule Conflict

struct ScheduleConflict: Identifiable {
    let id = UUID()
    var type: ConflictType
    var description: String
    var classIds: [String]

    enum ConflictType {
        case childDoubleBooked
        case parentDoubleBooked
        case unassignedTransportation

        var iconName: String {
            switch self {
            case .childDoubleBooked: return "person.2.fill"
            case .parentDoubleBooked: return "car.fill"
            case .unassignedTransportation: return "exclamationmark.triangle.fill"
            }
        }
    }
}
