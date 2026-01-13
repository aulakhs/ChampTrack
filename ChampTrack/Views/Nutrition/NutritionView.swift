import SwiftUI

struct NutritionView: View {
    @EnvironmentObject var dataService: DataService
    @State private var selectedChild: Child?
    @State private var selectedDate = Date()
    @State private var showAddMeal = false
    @State private var hydrationGlasses = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Child selector
                    if !dataService.children.isEmpty {
                        childSelector
                    }

                    if let child = selectedChild ?? dataService.children.first {
                        // Date selector
                        dateSelector

                        // Nutrition progress
                        nutritionProgress(for: child)

                        // Hydration tracker
                        hydrationTracker

                        // Today's meals
                        mealsSection(for: child)
                    } else {
                        EmptyStateCard(
                            icon: "person.badge.plus",
                            title: "No children added",
                            subtitle: "Add a child to start tracking nutrition"
                        )
                    }
                }
                .padding()
            }
            .background(Color.softBackground)
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddMeal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.championBlue)
                    }
                    .disabled(dataService.children.isEmpty)
                }
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView(preselectedChild: selectedChild ?? dataService.children.first)
            }
            .onAppear {
                if selectedChild == nil {
                    selectedChild = dataService.children.first
                }
            }
        }
    }

    // MARK: - Components

    private var childSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(dataService.children) { child in
                    ChildSelectionCard(
                        child: child,
                        isSelected: selectedChild?.id == child.id,
                        onTap: { selectedChild = child }
                    )
                }
            }
        }
    }

    private var dateSelector: some View {
        HStack {
            Button(action: { navigateDate(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.championBlue)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(dateFormatted)
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                if Calendar.current.isDateInToday(selectedDate) {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.championBlue)
                }
            }

            Spacer()

            Button(action: { navigateDate(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.championBlue)
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private func nutritionProgress(for child: Child) -> some View {
        let daily = dataService.getDailyNutrition(for: child.id, on: selectedDate)
        let target = dataService.nutritionTargets[child.id] ?? NutritionTarget.calculate(
            for: child,
            activityLevel: .moderate
        )

        return NutritionProgressCard(
            calories: (current: daily.calories, target: target.calories),
            protein: (current: daily.protein, target: target.protein),
            carbs: (current: daily.carbs, target: target.carbs),
            fats: (current: daily.fats, target: target.fats)
        )
    }

    private var hydrationTracker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.championBlue)
                Text("Hydration")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                Text("\(hydrationGlasses) / 8 glasses")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            // Water glasses
            HStack(spacing: 8) {
                ForEach(0..<8) { index in
                    Button(action: {
                        if index < hydrationGlasses {
                            hydrationGlasses = index
                        } else {
                            hydrationGlasses = index + 1
                        }
                    }) {
                        Image(systemName: index < hydrationGlasses ? "drop.fill" : "drop")
                            .font(.title2)
                            .foregroundColor(index < hydrationGlasses ? .championBlue : .gray.opacity(0.3))
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.championBlue)
                        .frame(width: geometry.size.width * (Double(hydrationGlasses) / 8.0), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    private func mealsSection(for child: Child) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Meals")
                .font(.headline)
                .foregroundColor(.textPrimary)

            let meals = dataService.getMeals(for: child.id, on: selectedDate)

            if meals.isEmpty {
                EmptyStateCard(
                    icon: "fork.knife",
                    title: "No meals logged",
                    subtitle: "Tap + to log a meal"
                )
            } else {
                ForEach(meals) { meal in
                    MealCard(meal: meal)
                }
            }

            // Quick add buttons
            HStack(spacing: 12) {
                ForEach(MealType.allCases, id: \.self) { type in
                    QuickMealButton(mealType: type) {
                        showAddMeal = true
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    private func navigateDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// MARK: - Supporting Views

struct MealCard: View {
    let meal: Meal

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: meal.mealType.iconName)
                    .foregroundColor(.championBlue)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.mealType.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)

                    Text(timeFormatter.string(from: meal.date))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Text("\(Int(meal.totalCalories)) kcal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.championBlue)
            }

            // Food items
            if !meal.foods.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(meal.foods) { food in
                        HStack {
                            Text(food.name)
                                .font(.caption)
                                .foregroundColor(.textPrimary)

                            Spacer()

                            Text("\(Int(food.calories)) kcal")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(.top, 4)
            }

            // Macros summary
            HStack(spacing: 16) {
                MacroPill(label: "P", value: Int(meal.totalProtein), color: .accentRed)
                MacroPill(label: "C", value: Int(meal.totalCarbs), color: .victoryGold)
                MacroPill(label: "F", value: Int(meal.totalFats), color: .accentPurple)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct MacroPill: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text("\(value)g")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QuickMealButton: View {
    let mealType: MealType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: mealType.iconName)
                    .font(.title3)
                Text(mealType.displayName)
                    .font(.caption2)
            }
            .foregroundColor(.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(8)
        }
    }
}

struct AddMealView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService

    var preselectedChild: Child?

    @State private var selectedChild: Child?
    @State private var mealType: MealType = .breakfast
    @State private var date = Date()
    @State private var foods: [FoodItem] = []
    @State private var notes = ""

    // Add food form
    @State private var showAddFood = false
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fats = ""
    @State private var portion = "1 serving"

    var body: some View {
        NavigationStack {
            Form {
                // Child selection
                if preselectedChild == nil {
                    Section("Child") {
                        Picker("Select Child", selection: $selectedChild) {
                            Text("Select a child").tag(nil as Child?)
                            ForEach(dataService.children) { child in
                                Text(child.firstName).tag(child as Child?)
                            }
                        }
                    }
                }

                // Meal details
                Section("Meal Details") {
                    Picker("Meal Type", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                Text(type.displayName)
                            }.tag(type)
                        }
                    }

                    DatePicker("Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                // Foods
                Section("Foods") {
                    ForEach(foods) { food in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(food.name)
                                    .font(.subheadline)
                                Text("\(Int(food.calories)) kcal - \(food.portion)")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()

                            Button(action: { foods.removeAll { $0.id == food.id } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }

                    Button(action: { showAddFood = true }) {
                        Label("Add Food", systemImage: "plus.circle.fill")
                            .foregroundColor(.championBlue)
                    }
                }

                // Quick add common foods
                Section("Quick Add") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            QuickFoodButton(name: "Apple", calories: 95) { addQuickFood($0) }
                            QuickFoodButton(name: "Banana", calories: 105) { addQuickFood($0) }
                            QuickFoodButton(name: "Eggs (2)", calories: 156) { addQuickFood($0) }
                            QuickFoodButton(name: "Milk", calories: 100) { addQuickFood($0) }
                            QuickFoodButton(name: "Bread", calories: 80) { addQuickFood($0) }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 8)
                }

                // Notes
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMeal()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAddFood) {
                addFoodSheet
            }
            .onAppear {
                selectedChild = preselectedChild ?? dataService.children.first
            }
        }
    }

    private var addFoodSheet: some View {
        NavigationStack {
            Form {
                Section("Food Details") {
                    TextField("Food Name", text: $foodName)
                    TextField("Calories", text: $calories)
                        .keyboardType(.numberPad)
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.decimalPad)
                    TextField("Carbs (g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    TextField("Fats (g)", text: $fats)
                        .keyboardType(.decimalPad)
                    TextField("Portion", text: $portion)
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showAddFood = false
                        clearFoodForm()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addFood()
                    }
                    .disabled(foodName.isEmpty || calories.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var isFormValid: Bool {
        let child = preselectedChild ?? selectedChild
        return child != nil && !foods.isEmpty
    }

    private func addFood() {
        let food = FoodItem(
            name: foodName,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fats: Double(fats) ?? 0,
            portion: portion
        )
        foods.append(food)
        showAddFood = false
        clearFoodForm()
    }

    private func addQuickFood(_ food: FoodItem) {
        foods.append(food)
    }

    private func clearFoodForm() {
        foodName = ""
        calories = ""
        protein = ""
        carbs = ""
        fats = ""
        portion = "1 serving"
    }

    private func saveMeal() {
        guard let child = preselectedChild ?? selectedChild else { return }

        let meal = Meal(
            childId: child.id,
            date: date,
            mealType: mealType,
            foods: foods,
            notes: notes.isEmpty ? nil : notes
        )

        dataService.addMeal(meal)
        dismiss()
    }
}

struct QuickFoodButton: View {
    let name: String
    let calories: Int
    let onAdd: (FoodItem) -> Void

    var body: some View {
        Button(action: {
            onAdd(FoodItem(
                name: name,
                calories: Double(calories),
                protein: 0,
                carbs: 0,
                fats: 0,
                portion: "1 serving"
            ))
        }) {
            VStack(spacing: 2) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(calories) kcal")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.championBlue.opacity(0.1))
            .foregroundColor(.championBlue)
            .cornerRadius(8)
        }
    }
}

#Preview {
    NutritionView()
        .environmentObject(DataService())
}
