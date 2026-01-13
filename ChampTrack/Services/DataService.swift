import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

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
    @Published var errorMessage: String?

    // Firestore reference
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    // Current family ID (set after login/family creation)
    var currentFamilyId: String? {
        didSet {
            if let familyId = currentFamilyId {
                setupListeners(for: familyId)
            }
        }
    }

    init() {
        // For demo purposes, create a default family
        // In production, this would be set after authentication
        createOrJoinFamily(name: "My Family", userId: "demo-user")
    }


    // MARK: - Listener Management

    private func removeListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }

    private func setupListeners(for familyId: String) {
        removeListeners()
        isLoading = true

        // Listen to family document
        let familyListener = db.collection("families").document(familyId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                if let data = snapshot?.data() {
                    self.family = Family(
                        id: familyId,
                        name: data["name"] as? String ?? "",
                        createdBy: data["createdBy"] as? String ?? "",
                        members: data["members"] as? [String] ?? []
                    )
                }
            }
        listeners.append(familyListener)

        // Listen to children
        let childrenListener = db.collection("children")
            .whereField("familyId", isEqualTo: familyId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.children = snapshot?.documents.compactMap { doc in
                    self.childFromDocument(doc)
                } ?? []

                // Calculate nutrition targets for all children
                for child in self.children {
                    self.calculateNutritionTarget(for: child)
                }
            }
        listeners.append(childrenListener)

        // Listen to sports
        let sportsListener = db.collection("sports")
            .whereField("familyId", isEqualTo: familyId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.sports = snapshot?.documents.compactMap { doc in
                    self.sportFromDocument(doc)
                } ?? []
            }
        listeners.append(sportsListener)

        // Listen to classes
        let classesListener = db.collection("classes")
            .whereField("familyId", isEqualTo: familyId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.classes = snapshot?.documents.compactMap { doc in
                    self.sportClassFromDocument(doc)
                } ?? []
                self.isLoading = false
            }
        listeners.append(classesListener)

        // Listen to meals
        let mealsListener = db.collection("meals")
            .whereField("familyId", isEqualTo: familyId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.meals = snapshot?.documents.compactMap { doc in
                    self.mealFromDocument(doc)
                } ?? []
            }
        listeners.append(mealsListener)

        // Listen to goals
        let goalsListener = db.collection("goals")
            .whereField("familyId", isEqualTo: familyId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.goals = snapshot?.documents.compactMap { doc in
                    self.goalFromDocument(doc)
                } ?? []
            }
        listeners.append(goalsListener)

        // Listen to achievements
        let achievementsListener = db.collection("achievements")
            .whereField("familyId", isEqualTo: familyId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.achievements = snapshot?.documents.compactMap { doc in
                    self.achievementFromDocument(doc)
                } ?? []
            }
        listeners.append(achievementsListener)
    }

    // MARK: - Family Management

    func createOrJoinFamily(name: String, userId: String) {
        let familyId = UUID().uuidString
        let familyData: [String: Any] = [
            "name": name,
            "createdBy": userId,
            "members": [userId],
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("families").document(familyId).setData(familyData) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.currentFamilyId = familyId
            }
        }
    }

    func joinFamily(familyId: String, userId: String) {
        db.collection("families").document(familyId).updateData([
            "members": FieldValue.arrayUnion([userId])
        ]) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.currentFamilyId = familyId
            }
        }
    }

    // MARK: - Child Management

    func addChild(_ child: Child) {
        guard let familyId = currentFamilyId else { return }

        var childData = childToData(child)
        childData["familyId"] = familyId

        db.collection("children").document(child.id).setData(childData) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.generateAchievementsForChild(child)
            }
        }
    }

    func updateChild(_ child: Child) {
        let childData = childToData(child)
        db.collection("children").document(child.id).updateData(childData) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func deleteChild(id: String) {
        // Delete child document
        db.collection("children").document(id).delete()

        // Delete related sports
        db.collection("sports").whereField("childId", isEqualTo: id).getDocuments { [weak self] snapshot, _ in
            snapshot?.documents.forEach { $0.reference.delete() }
        }

        // Delete related classes
        db.collection("classes").whereField("childId", isEqualTo: id).getDocuments { snapshot, _ in
            snapshot?.documents.forEach { $0.reference.delete() }
        }

        // Delete related meals
        db.collection("meals").whereField("childId", isEqualTo: id).getDocuments { snapshot, _ in
            snapshot?.documents.forEach { $0.reference.delete() }
        }

        // Delete related goals
        db.collection("goals").whereField("childId", isEqualTo: id).getDocuments { snapshot, _ in
            snapshot?.documents.forEach { $0.reference.delete() }
        }

        // Delete related achievements
        db.collection("achievements").whereField("childId", isEqualTo: id).getDocuments { snapshot, _ in
            snapshot?.documents.forEach { $0.reference.delete() }
        }

        nutritionTargets.removeValue(forKey: id)
    }

    func getChild(id: String) -> Child? {
        children.first { $0.id == id }
    }

    // MARK: - Sports Management

    func addSport(_ sport: Sport) {
        guard let familyId = currentFamilyId else { return }

        var sportData = sportToData(sport)
        sportData["familyId"] = familyId

        db.collection("sports").document(sport.id).setData(sportData) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func updateSport(_ sport: Sport) {
        let sportData = sportToData(sport)
        db.collection("sports").document(sport.id).updateData(sportData) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func deleteSport(id: String) {
        db.collection("sports").document(id).delete()

        // Delete related classes
        db.collection("classes").whereField("sportId", isEqualTo: id).getDocuments { snapshot, _ in
            snapshot?.documents.forEach { $0.reference.delete() }
        }
    }

    func getSports(for childId: String) -> [Sport] {
        sports.filter { $0.childId == childId }
    }

    // MARK: - Class Management

    func addClass(_ sportClass: SportClass) {
        guard let familyId = currentFamilyId else { return }

        var classData = sportClassToData(sportClass)
        classData["familyId"] = familyId

        db.collection("classes").document(sportClass.id).setData(classData) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func updateClass(_ sportClass: SportClass) {
        let classData = sportClassToData(sportClass)
        db.collection("classes").document(sportClass.id).updateData(classData) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func deleteClass(id: String) {
        db.collection("classes").document(id).delete()
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
        var updates: [String: Any] = [:]
        if let dropoff = dropoff {
            updates["dropoffAssignedTo"] = dropoff
        }
        if let pickup = pickup {
            updates["pickupAssignedTo"] = pickup
        }

        db.collection("classes").document(classId).updateData(updates)
    }

    func markClassComplete(id: String) {
        db.collection("classes").document(id).updateData(["status": "completed"])

        if let sportClass = classes.first(where: { $0.id == id }) {
            awardPointsForClass(sportClass)
        }
    }

    // MARK: - Nutrition Management

    func addMeal(_ meal: Meal) {
        guard let familyId = currentFamilyId else { return }

        var mealData = mealToData(meal)
        mealData["familyId"] = familyId

        db.collection("meals").document(meal.id).setData(mealData) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.checkNutritionGoals(for: meal.childId, on: meal.date)
            }
        }
    }

    func updateMeal(_ meal: Meal) {
        let mealData = mealToData(meal)
        db.collection("meals").document(meal.id).updateData(mealData)
    }

    func deleteMeal(id: String) {
        db.collection("meals").document(id).delete()
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
        guard let familyId = currentFamilyId else { return }

        var goalData = goalToData(goal)
        goalData["familyId"] = familyId

        db.collection("goals").document(goal.id).setData(goalData) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func updateGoal(_ goal: Goal) {
        let goalData = goalToData(goal)
        db.collection("goals").document(goal.id).updateData(goalData) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func deleteGoal(id: String) {
        db.collection("goals").document(id).delete()
    }

    func getGoals(for childId: String) -> [Goal] {
        goals.filter { $0.childId == childId }
    }

    func getActiveGoals(for childId: String) -> [Goal] {
        goals.filter { $0.childId == childId && $0.status == .active }
    }

    func completeGoal(id: String) {
        if let goal = goals.first(where: { $0.id == id }) {
            db.collection("goals").document(id).updateData([
                "status": "completed",
                "currentValue": goal.targetValue
            ])
            awardPointsForGoal(goal)
        }
    }

    func updateGoalProgress(id: String, newValue: Double) {
        db.collection("goals").document(id).updateData([
            "currentValue": newValue
        ])

        if let goal = goals.first(where: { $0.id == id }),
           newValue >= goal.targetValue {
            completeGoal(id: id)
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
        if let achievement = achievements.first(where: { $0.id == id && !$0.isUnlocked }) {
            db.collection("achievements").document(id).updateData([
                "isUnlocked": true,
                "earnedDate": Timestamp(date: Date())
            ])
            awardPoints(to: achievement.childId, points: achievement.pointsAwarded)
        }
    }

    // MARK: - Points Management

    func awardPoints(to childId: String, points: Int) {
        if let child = children.first(where: { $0.id == childId }) {
            let newPoints = child.totalPoints + points
            let newLevel = calculateLevel(for: newPoints)

            db.collection("children").document(childId).updateData([
                "totalPoints": newPoints,
                "currentLevel": newLevel
            ])

            checkMilestoneAchievements(for: childId)
        }
    }

    private func calculateLevel(for points: Int) -> Int {
        let thresholds = [0, 100, 250, 500, 800, 1200, 1700, 2300, 3000, 3800, 4700, 5700, 6800, 8000, 9300, 10700, 12200, 13800, 15500, 17300]

        var level = 1
        for (index, threshold) in thresholds.enumerated() {
            if points >= threshold {
                level = index + 1
            }
        }
        return level
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

        let caloriesMet = daily.calories >= target.calories * 0.9
        let proteinMet = daily.protein >= target.protein * 0.9

        if caloriesMet && proteinMet {
            awardPoints(to: childId, points: 15)
        }
    }

    private func checkMilestoneAchievements(for childId: String) {
        if let child = getChild(id: childId) {
            if child.totalPoints >= 100 {
                if let achievement = achievements.first(where: { $0.childId == childId && $0.title == "Century Club" && !$0.isUnlocked }) {
                    unlockAchievement(id: achievement.id)
                }
            }
        }
    }

    private func generateAchievementsForChild(_ child: Child) {
        guard let familyId = currentFamilyId else { return }

        let templates = Achievement.templates
        for template in templates {
            var achievement = template
            achievement.childId = child.id

            var achievementData = achievementToData(achievement)
            achievementData["familyId"] = familyId

            db.collection("achievements").document(achievement.id).setData(achievementData)
        }
    }

    // MARK: - Conflict Detection

    func detectConflicts(for date: Date) -> [ScheduleConflict] {
        var conflicts: [ScheduleConflict] = []
        let dayClasses = getClasses(for: date)

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

    // MARK: - Data Conversion Helpers

    private func childToData(_ child: Child) -> [String: Any] {
        return [
            "familyId": child.familyId,
            "firstName": child.firstName,
            "lastName": child.lastName,
            "dateOfBirth": Timestamp(date: child.dateOfBirth),
            "gender": child.gender.rawValue,
            "weight": child.weight,
            "height": child.height,
            "photoURL": child.photoURL ?? "",
            "allergies": child.allergies,
            "schoolGrade": child.schoolGrade ?? "",
            "totalPoints": child.totalPoints,
            "currentLevel": child.currentLevel,
            "createdAt": Timestamp(date: child.createdAt)
        ]
    }

    private func childFromDocument(_ doc: DocumentSnapshot) -> Child? {
        guard let data = doc.data() else { return nil }

        return Child(
            id: doc.documentID,
            familyId: data["familyId"] as? String ?? "",
            firstName: data["firstName"] as? String ?? "",
            lastName: data["lastName"] as? String ?? "",
            dateOfBirth: (data["dateOfBirth"] as? Timestamp)?.dateValue() ?? Date(),
            gender: Gender(rawValue: data["gender"] as? String ?? "other") ?? .other,
            weight: data["weight"] as? Double ?? 0,
            height: data["height"] as? Double ?? 0,
            photoURL: data["photoURL"] as? String,
            allergies: data["allergies"] as? [String] ?? [],
            schoolGrade: data["schoolGrade"] as? String,
            totalPoints: data["totalPoints"] as? Int ?? 0,
            currentLevel: data["currentLevel"] as? Int ?? 1,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    private func sportToData(_ sport: Sport) -> [String: Any] {
        var data: [String: Any] = [
            "childId": sport.childId,
            "familyId": sport.familyId,
            "sportName": sport.sportName,
            "colorHex": sport.colorHex,
            "iconName": sport.iconName,
            "isActive": sport.isActive,
            "createdAt": Timestamp(date: sport.createdAt)
        ]

        if let teamName = sport.teamName { data["teamName"] = teamName }
        if let coachName = sport.coachName { data["coachName"] = coachName }
        if let coachContact = sport.coachContact { data["coachContact"] = coachContact }
        if let seasonStart = sport.seasonStart { data["seasonStart"] = Timestamp(date: seasonStart) }
        if let seasonEnd = sport.seasonEnd { data["seasonEnd"] = Timestamp(date: seasonEnd) }
        if let location = sport.location { data["location"] = location }

        return data
    }

    private func sportFromDocument(_ doc: DocumentSnapshot) -> Sport? {
        guard let data = doc.data() else { return nil }

        return Sport(
            id: doc.documentID,
            childId: data["childId"] as? String ?? "",
            familyId: data["familyId"] as? String ?? "",
            sportName: data["sportName"] as? String ?? "",
            teamName: data["teamName"] as? String,
            coachName: data["coachName"] as? String,
            coachContact: data["coachContact"] as? String,
            seasonStart: (data["seasonStart"] as? Timestamp)?.dateValue(),
            seasonEnd: (data["seasonEnd"] as? Timestamp)?.dateValue(),
            location: data["location"] as? String,
            colorHex: data["colorHex"] as? String ?? "4A90E2",
            iconName: data["iconName"] as? String ?? "sportscourt.fill",
            isActive: data["isActive"] as? Bool ?? true,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    private func sportClassToData(_ sportClass: SportClass) -> [String: Any] {
        var data: [String: Any] = [
            "sportId": sportClass.sportId,
            "childId": sportClass.childId,
            "familyId": sportClass.familyId,
            "type": sportClass.type.rawValue,
            "dateTime": Timestamp(date: sportClass.dateTime),
            "duration": sportClass.duration,
            "recurringFrequency": sportClass.recurringFrequency.rawValue,
            "equipmentNeeded": sportClass.equipmentNeeded,
            "status": sportClass.status.rawValue,
            "createdAt": Timestamp(date: sportClass.createdAt)
        ]

        if let location = sportClass.location {
            data["location"] = ["name": location.name, "address": location.address ?? ""]
        }
        if let recurringUntil = sportClass.recurringUntil {
            data["recurringUntil"] = Timestamp(date: recurringUntil)
        }
        if let dropoff = sportClass.dropoffAssignedTo { data["dropoffAssignedTo"] = dropoff }
        if let pickup = sportClass.pickupAssignedTo { data["pickupAssignedTo"] = pickup }
        if let notes = sportClass.notes { data["notes"] = notes }

        return data
    }

    private func sportClassFromDocument(_ doc: DocumentSnapshot) -> SportClass? {
        guard let data = doc.data() else { return nil }

        var location: Location? = nil
        if let locationData = data["location"] as? [String: Any] {
            location = Location(
                name: locationData["name"] as? String ?? "",
                address: locationData["address"] as? String
            )
        }

        return SportClass(
            id: doc.documentID,
            sportId: data["sportId"] as? String ?? "",
            childId: data["childId"] as? String ?? "",
            familyId: data["familyId"] as? String ?? "",
            type: ClassType(rawValue: data["type"] as? String ?? "practice") ?? .practice,
            dateTime: (data["dateTime"] as? Timestamp)?.dateValue() ?? Date(),
            duration: data["duration"] as? Int ?? 60,
            location: location,
            recurringFrequency: RecurringFrequency(rawValue: data["recurringFrequency"] as? String ?? "none") ?? .none,
            recurringUntil: (data["recurringUntil"] as? Timestamp)?.dateValue(),
            dropoffAssignedTo: data["dropoffAssignedTo"] as? String,
            pickupAssignedTo: data["pickupAssignedTo"] as? String,
            notes: data["notes"] as? String,
            equipmentNeeded: data["equipmentNeeded"] as? [String] ?? [],
            status: ClassStatus(rawValue: data["status"] as? String ?? "scheduled") ?? .scheduled,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    private func mealToData(_ meal: Meal) -> [String: Any] {
        let foodsData = meal.foods.map { food -> [String: Any] in
            var foodDict: [String: Any] = [
                "id": food.id,
                "name": food.name,
                "calories": food.calories,
                "protein": food.protein,
                "carbs": food.carbs,
                "fats": food.fats,
                "portion": food.portion
            ]
            if let portionGrams = food.portionGrams {
                foodDict["portionGrams"] = portionGrams
            }
            return foodDict
        }

        var data: [String: Any] = [
            "childId": meal.childId,
            "date": Timestamp(date: meal.date),
            "mealType": meal.mealType.rawValue,
            "photoURLs": meal.photoURLs,
            "foods": foodsData,
            "createdAt": Timestamp(date: meal.createdAt)
        ]
        if let notes = meal.notes { data["notes"] = notes }

        return data
    }

    private func mealFromDocument(_ doc: DocumentSnapshot) -> Meal? {
        guard let data = doc.data() else { return nil }

        let foodsData = data["foods"] as? [[String: Any]] ?? []
        let foods = foodsData.map { foodData -> FoodItem in
            FoodItem(
                id: foodData["id"] as? String ?? UUID().uuidString,
                name: foodData["name"] as? String ?? "",
                calories: foodData["calories"] as? Double ?? 0,
                protein: foodData["protein"] as? Double ?? 0,
                carbs: foodData["carbs"] as? Double ?? 0,
                fats: foodData["fats"] as? Double ?? 0,
                portion: foodData["portion"] as? String ?? "1 serving",
                portionGrams: foodData["portionGrams"] as? Double
            )
        }

        return Meal(
            id: doc.documentID,
            childId: data["childId"] as? String ?? "",
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            mealType: MealType(rawValue: data["mealType"] as? String ?? "snack") ?? .snack,
            photoURLs: data["photoURLs"] as? [String] ?? [],
            foods: foods,
            notes: data["notes"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    private func goalToData(_ goal: Goal) -> [String: Any] {
        let milestonesData = goal.milestones.map { milestone -> [String: Any] in
            var data: [String: Any] = [
                "id": milestone.id,
                "title": milestone.title,
                "targetValue": milestone.targetValue,
                "isCompleted": milestone.isCompleted
            ]
            if let completedAt = milestone.completedAt {
                data["completedAt"] = Timestamp(date: completedAt)
            }
            return data
        }

        var data: [String: Any] = [
            "childId": goal.childId,
            "familyId": goal.familyId,
            "type": goal.type.rawValue,
            "title": goal.title,
            "targetValue": goal.targetValue,
            "currentValue": goal.currentValue,
            "unit": goal.unit,
            "startDate": Timestamp(date: goal.startDate),
            "endDate": Timestamp(date: goal.endDate),
            "status": goal.status.rawValue,
            "priority": goal.priority.rawValue,
            "milestones": milestonesData,
            "pointsReward": goal.pointsReward,
            "createdAt": Timestamp(date: goal.createdAt)
        ]

        if let description = goal.description { data["description"] = description }
        if let relatedSportId = goal.relatedSportId { data["relatedSportId"] = relatedSportId }
        if let parentNotes = goal.parentNotes { data["parentNotes"] = parentNotes }
        if let childNotes = goal.childNotes { data["childNotes"] = childNotes }

        return data
    }

    private func goalFromDocument(_ doc: DocumentSnapshot) -> Goal? {
        guard let data = doc.data() else { return nil }

        let milestonesData = data["milestones"] as? [[String: Any]] ?? []
        let milestones = milestonesData.map { milestoneData -> Milestone in
            Milestone(
                id: milestoneData["id"] as? String ?? UUID().uuidString,
                title: milestoneData["title"] as? String ?? "",
                targetValue: milestoneData["targetValue"] as? Double ?? 0,
                isCompleted: milestoneData["isCompleted"] as? Bool ?? false,
                completedAt: (milestoneData["completedAt"] as? Timestamp)?.dateValue()
            )
        }

        return Goal(
            id: doc.documentID,
            childId: data["childId"] as? String ?? "",
            familyId: data["familyId"] as? String ?? "",
            type: GoalType(rawValue: data["type"] as? String ?? "personal") ?? .personal,
            title: data["title"] as? String ?? "",
            description: data["description"] as? String,
            targetValue: data["targetValue"] as? Double ?? 0,
            currentValue: data["currentValue"] as? Double ?? 0,
            unit: data["unit"] as? String ?? "",
            startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
            endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
            status: GoalStatus(rawValue: data["status"] as? String ?? "active") ?? .active,
            priority: GoalPriority(rawValue: data["priority"] as? String ?? "medium") ?? .medium,
            relatedSportId: data["relatedSportId"] as? String,
            parentNotes: data["parentNotes"] as? String,
            childNotes: data["childNotes"] as? String,
            milestones: milestones,
            pointsReward: data["pointsReward"] as? Int ?? 100,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    private func achievementToData(_ achievement: Achievement) -> [String: Any] {
        var data: [String: Any] = [
            "childId": achievement.childId,
            "type": achievement.type.rawValue,
            "category": achievement.category.rawValue,
            "title": achievement.title,
            "description": achievement.description,
            "iconName": achievement.iconName,
            "tier": achievement.tier.rawValue,
            "pointsAwarded": achievement.pointsAwarded,
            "isUnlocked": achievement.isUnlocked,
            "createdAt": Timestamp(date: achievement.createdAt)
        ]

        if let earnedDate = achievement.earnedDate {
            data["earnedDate"] = Timestamp(date: earnedDate)
        }
        if let progress = achievement.progress { data["progress"] = progress }
        if let requirement = achievement.requirement { data["requirement"] = requirement }
        if let relatedGoalId = achievement.relatedGoalId { data["relatedGoalId"] = relatedGoalId }

        return data
    }

    private func achievementFromDocument(_ doc: DocumentSnapshot) -> Achievement? {
        guard let data = doc.data() else { return nil }

        return Achievement(
            id: doc.documentID,
            childId: data["childId"] as? String ?? "",
            type: AchievementType(rawValue: data["type"] as? String ?? "badge") ?? .badge,
            category: AchievementCategory(rawValue: data["category"] as? String ?? "milestone") ?? .milestone,
            title: data["title"] as? String ?? "",
            description: data["description"] as? String ?? "",
            iconName: data["iconName"] as? String ?? "star.fill",
            tier: AchievementTier(rawValue: data["tier"] as? String ?? "bronze") ?? .bronze,
            pointsAwarded: data["pointsAwarded"] as? Int ?? 0,
            earnedDate: (data["earnedDate"] as? Timestamp)?.dateValue(),
            relatedGoalId: data["relatedGoalId"] as? String,
            isUnlocked: data["isUnlocked"] as? Bool ?? false,
            progress: data["progress"] as? Double,
            requirement: data["requirement"] as? Double,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
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
