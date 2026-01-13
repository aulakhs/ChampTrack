import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var dataService: DataService
    @State private var selectedChild: Child?
    @State private var selectedFilter: GoalFilter = .active
    @State private var showAddGoal = false

    enum GoalFilter: String, CaseIterable {
        case active = "Active"
        case completed = "Completed"
        case all = "All"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Child selector
                if !dataService.children.isEmpty {
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
                        .padding()
                    }
                }

                // Filter
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(GoalFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Goals list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let child = selectedChild ?? dataService.children.first {
                            let goals = filteredGoals(for: child)

                            if goals.isEmpty {
                                EmptyStateCard(
                                    icon: "target",
                                    title: "No \(selectedFilter.rawValue.lowercased()) goals",
                                    subtitle: "Tap + to create a new goal"
                                )
                                .padding(.top, 20)
                            } else {
                                ForEach(goals) { goal in
                                    NavigationLink(destination: GoalDetailView(goal: goal)) {
                                        GoalCard(goal: goal)
                                    }
                                }
                            }
                        } else {
                            EmptyStateCard(
                                icon: "person.badge.plus",
                                title: "No children added",
                                subtitle: "Add a child to start setting goals"
                            )
                            .padding(.top, 20)
                        }
                    }
                    .padding()
                }
            }
            .background(Color.softBackground)
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddGoal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.championBlue)
                    }
                    .disabled(dataService.children.isEmpty)
                }
            }
            .sheet(isPresented: $showAddGoal) {
                AddGoalView(preselectedChild: selectedChild ?? dataService.children.first)
            }
            .onAppear {
                if selectedChild == nil {
                    selectedChild = dataService.children.first
                }
            }
        }
    }

    private func filteredGoals(for child: Child) -> [Goal] {
        let goals = dataService.getGoals(for: child.id)

        switch selectedFilter {
        case .active:
            return goals.filter { $0.status == .active }
        case .completed:
            return goals.filter { $0.status == .completed }
        case .all:
            return goals
        }
    }
}

struct GoalDetailView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) var dismiss
    @State var goal: Goal
    @State private var showEditProgress = false
    @State private var newProgress: Double = 0
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress card
                VStack(spacing: 16) {
                    ProgressRing(
                        progress: goal.progressPercentage / 100,
                        lineWidth: 12,
                        size: 120,
                        color: typeColor
                    )

                    Text(goal.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    if let description = goal.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 20) {
                        StatBox(title: "Current", value: "\(Int(goal.currentValue))")
                        StatBox(title: "Target", value: "\(Int(goal.targetValue))")
                        StatBox(title: "Days Left", value: "\(goal.daysRemaining)")
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)

                // Quick actions
                HStack(spacing: 12) {
                    Button(action: { showEditProgress = true }) {
                        Label("Update Progress", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(QuickActionButtonStyle(color: .championBlue))

                    if goal.status == .active && goal.isComplete {
                        Button(action: completeGoal) {
                            Label("Complete", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(QuickActionButtonStyle(color: .success))
                    }
                }

                // Details
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(title: "Type", value: goal.type.displayName, icon: goal.type.iconName)
                    DetailRow(title: "Priority", value: goal.priority.displayName, icon: "flag.fill")
                    DetailRow(title: "Start Date", value: formatDate(goal.startDate), icon: "calendar")
                    DetailRow(title: "End Date", value: formatDate(goal.endDate), icon: "calendar.badge.clock")
                    DetailRow(title: "Reward", value: "\(goal.pointsReward) points", icon: "star.fill")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)

                // Milestones
                if !goal.milestones.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Milestones")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        ForEach(goal.milestones) { milestone in
                            MilestoneRow(milestone: milestone)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                }

                // Notes
                if goal.parentNotes != nil || goal.childNotes != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        if let notes = goal.parentNotes {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Parent Notes")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundColor(.textPrimary)
                            }
                        }

                        if let notes = goal.childNotes {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Child Notes")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .background(Color.softBackground)
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showEditSheet = true }) {
                        Label("Edit Goal", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete Goal", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.championBlue)
                }
            }
        }
        .sheet(isPresented: $showEditProgress) {
            updateProgressSheet
        }
        .sheet(isPresented: $showEditSheet) {
            EditGoalView(goal: $goal)
        }
        .alert("Delete Goal", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dataService.deleteGoal(id: goal.id)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(goal.title)\"? This action cannot be undone.")
        }
    }

    private var updateProgressSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Update Progress")
                    .font(.headline)

                VStack(spacing: 8) {
                    Text("\(Int(newProgress))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.championBlue)

                    Text("of \(Int(goal.targetValue)) \(goal.unit)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Slider(
                    value: $newProgress,
                    in: 0...goal.targetValue,
                    step: 1
                )
                .tint(.championBlue)
                .padding(.horizontal)

                HStack(spacing: 16) {
                    Button("-1") {
                        newProgress = max(0, newProgress - 1)
                    }
                    .buttonStyle(IncrementButtonStyle())

                    Button("+1") {
                        newProgress = min(goal.targetValue, newProgress + 1)
                    }
                    .buttonStyle(IncrementButtonStyle())
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showEditProgress = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dataService.updateGoalProgress(id: goal.id, newValue: newProgress)
                        goal.currentValue = newProgress
                        showEditProgress = false
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                newProgress = goal.currentValue
            }
        }
        .presentationDetents([.medium])
    }

    private var typeColor: Color {
        switch goal.type {
        case .sports: return .championBlue
        case .nutrition: return .energyGreen
        case .attendance: return .victoryGold
        case .personal: return .accentPurple
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func completeGoal() {
        dataService.completeGoal(id: goal.id)
        goal.status = .completed
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.softBackground)
        .cornerRadius(8)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.championBlue)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
        }
    }
}

struct MilestoneRow: View {
    let milestone: Milestone

    var body: some View {
        HStack {
            Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(milestone.isCompleted ? .success : .textSecondary)

            Text(milestone.title)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
                .strikethrough(milestone.isCompleted)

            Spacer()

            Text("\(Int(milestone.targetValue))")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

struct QuickActionButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding()
            .background(color)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct IncrementButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.championBlue)
            .frame(width: 60, height: 44)
            .background(Color.championBlue.opacity(0.1))
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService

    var preselectedChild: Child?

    @State private var selectedChild: Child?
    @State private var goalType: GoalType = .sports
    @State private var title = ""
    @State private var description = ""
    @State private var targetValue = ""
    @State private var unit = ""
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    @State private var priority: GoalPriority = .medium
    @State private var pointsReward = "100"

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

                Section("Goal Details") {
                    TextField("Goal Title", text: $title)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)

                    Picker("Type", selection: $goalType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName).tag(type)
                        }
                    }
                }

                Section("Target") {
                    HStack {
                        TextField("Target Value", text: $targetValue)
                            .keyboardType(.numberPad)
                        TextField("Unit (e.g., goals, days)", text: $unit)
                    }
                }

                Section("Timeline") {
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)

                    Picker("Priority", selection: $priority) {
                        ForEach(GoalPriority.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                }

                Section("Reward") {
                    HStack {
                        Text("Points")
                        Spacer()
                        TextField("Points", text: $pointsReward)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        saveGoal()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedChild = preselectedChild ?? dataService.children.first
            }
        }
    }

    private var isFormValid: Bool {
        let child = preselectedChild ?? selectedChild
        return child != nil && !title.isEmpty && !targetValue.isEmpty && !unit.isEmpty
    }

    private func saveGoal() {
        guard let child = preselectedChild ?? selectedChild else { return }

        let goal = Goal(
            childId: child.id,
            familyId: child.familyId,
            type: goalType,
            title: title,
            description: description.isEmpty ? nil : description,
            targetValue: Double(targetValue) ?? 0,
            unit: unit,
            endDate: endDate,
            priority: priority,
            pointsReward: Int(pointsReward) ?? 100
        )

        dataService.addGoal(goal)
        dismiss()
    }
}

struct EditGoalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @Binding var goal: Goal

    @State private var goalType: GoalType = .sports
    @State private var title = ""
    @State private var description = ""
    @State private var targetValue = ""
    @State private var unit = ""
    @State private var endDate = Date()
    @State private var priority: GoalPriority = .medium
    @State private var pointsReward = ""
    @State private var parentNotes = ""
    @State private var childNotes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal Title", text: $title)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)

                    Picker("Type", selection: $goalType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName).tag(type)
                        }
                    }
                }

                Section("Target") {
                    HStack {
                        TextField("Target Value", text: $targetValue)
                            .keyboardType(.numberPad)
                        TextField("Unit (e.g., goals, days)", text: $unit)
                    }
                }

                Section("Timeline") {
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)

                    Picker("Priority", selection: $priority) {
                        ForEach(GoalPriority.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                }

                Section("Reward") {
                    HStack {
                        Text("Points")
                        Spacer()
                        TextField("Points", text: $pointsReward)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section("Notes") {
                    TextField("Parent Notes (optional)", text: $parentNotes, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Child Notes (optional)", text: $childNotes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadGoalData()
            }
        }
    }

    private var isFormValid: Bool {
        !title.isEmpty && !targetValue.isEmpty && !unit.isEmpty
    }

    private func loadGoalData() {
        goalType = goal.type
        title = goal.title
        description = goal.description ?? ""
        targetValue = String(format: "%.0f", goal.targetValue)
        unit = goal.unit
        endDate = goal.endDate
        priority = goal.priority
        pointsReward = "\(goal.pointsReward)"
        parentNotes = goal.parentNotes ?? ""
        childNotes = goal.childNotes ?? ""
    }

    private func saveChanges() {
        goal.type = goalType
        goal.title = title
        goal.description = description.isEmpty ? nil : description
        goal.targetValue = Double(targetValue) ?? goal.targetValue
        goal.unit = unit
        goal.endDate = endDate
        goal.priority = priority
        goal.pointsReward = Int(pointsReward) ?? goal.pointsReward
        goal.parentNotes = parentNotes.isEmpty ? nil : parentNotes
        goal.childNotes = childNotes.isEmpty ? nil : childNotes

        dataService.updateGoal(goal)
        dismiss()
    }
}

#Preview {
    GoalsView()
        .environmentObject(DataService())
}
