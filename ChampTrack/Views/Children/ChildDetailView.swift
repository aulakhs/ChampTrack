import SwiftUI

struct ChildDetailView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) var dismiss
    @State var child: Child

    @State private var selectedTab = 0
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero section
                heroSection

                // Tab selector
                Picker("Section", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Sports").tag(1)
                    Text("Goals").tag(2)
                    Text("Achievements").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Content based on tab
                switch selectedTab {
                case 0:
                    overviewTab
                case 1:
                    sportsTab
                case 2:
                    goalsTab
                case 3:
                    achievementsTab
                default:
                    EmptyView()
                }
            }
            .padding()
        }
        .background(Color.softBackground)
        .navigationTitle(child.firstName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showEditSheet = true }) {
                        Label("Edit Child", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete Child", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.championBlue)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditChildView(child: $child)
        }
        .alert("Delete Child", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dataService.deleteChild(id: child.id)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \(child.firstName)? This will also delete all their sports, goals, and achievements.")
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            ChildAvatar(child: child, size: 100)

            VStack(spacing: 4) {
                Text(child.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Text("\(child.age) years old")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            // Level and points
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(child.totalPoints)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.victoryGold)
                    Text("Points")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("Lvl \(child.currentLevel)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.championBlue)
                    Text(child.levelTitle)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(child.pointsToNextLevel)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.energyGreen)
                    Text("To Next")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        VStack(spacing: 16) {
            // Physical info
            VStack(alignment: .leading, spacing: 12) {
                Text("Physical Info")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                HStack(spacing: 16) {
                    InfoCard(title: "Weight", value: "\(Int(child.weight)) kg", icon: "scalemass.fill")
                    InfoCard(title: "Height", value: "\(Int(child.height)) cm", icon: "ruler.fill")
                }
            }

            // Quick stats
            VStack(alignment: .leading, spacing: 12) {
                Text("Activity Summary")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                let sports = dataService.getSports(for: child.id)
                let goals = dataService.getActiveGoals(for: child.id)
                let achievements = dataService.getUnlockedAchievements(for: child.id)

                HStack(spacing: 12) {
                    QuickStatCard(title: "Sports", value: "\(sports.count)", color: .championBlue)
                    QuickStatCard(title: "Active Goals", value: "\(goals.count)", color: .victoryGold)
                    QuickStatCard(title: "Trophies", value: "\(achievements.count)", color: .accentPurple)
                }
            }

            // Allergies
            if !child.allergies.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Allergies")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    FlowLayout(spacing: 8) {
                        ForEach(child.allergies, id: \.self) { allergy in
                            Text(allergy)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentRed.opacity(0.1))
                                .foregroundColor(.accentRed)
                                .cornerRadius(16)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Sports Tab

    private var sportsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            let sports = dataService.getSports(for: child.id)

            if sports.isEmpty {
                EmptyStateCard(
                    icon: "sportscourt.fill",
                    title: "No sports added",
                    subtitle: "Add a sport to start tracking"
                )
            } else {
                ForEach(sports) { sport in
                    SportRow(sport: sport, child: child)
                }
            }

            NavigationLink(destination: AddSportView(preselectedChild: child)) {
                Label("Add Sport", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.championBlue.opacity(0.1))
                    .foregroundColor(.championBlue)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Goals Tab

    private var goalsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            let goals = dataService.getActiveGoals(for: child.id)

            if goals.isEmpty {
                EmptyStateCard(
                    icon: "target",
                    title: "No active goals",
                    subtitle: "Create a goal to track progress"
                )
            } else {
                ForEach(goals) { goal in
                    NavigationLink(destination: GoalDetailView(goal: goal)) {
                        CompactGoalCard(goal: goal)
                    }
                }
            }

            NavigationLink(destination: AddGoalView(preselectedChild: child)) {
                Label("Add Goal", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.championBlue.opacity(0.1))
                    .foregroundColor(.championBlue)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Achievements Tab

    private var achievementsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            let allAchievements = dataService.getAchievements(for: child.id)
            let unlocked = allAchievements.filter { $0.isUnlocked }
            let locked = allAchievements.filter { !$0.isUnlocked }

            // Unlocked
            if !unlocked.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Earned (\(unlocked.count))")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 90))
                    ], spacing: 12) {
                        ForEach(unlocked) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                }
            }

            // Locked
            if !locked.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Locked (\(locked.count))")
                        .font(.headline)
                        .foregroundColor(.textSecondary)

                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 90))
                    ], spacing: 12) {
                        ForEach(locked) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.championBlue)
                .frame(width: 44, height: 44)
                .background(Color.championBlue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(value)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct SportRow: View {
    let sport: Sport
    let child: Child
    @EnvironmentObject var dataService: DataService
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var editableSport: Sport

    init(sport: Sport, child: Child) {
        self.sport = sport
        self.child = child
        self._editableSport = State(initialValue: sport)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: sport.iconName)
                .font(.title2)
                .foregroundColor(sport.color)
                .frame(width: 44, height: 44)
                .background(sport.color.opacity(0.2))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(sport.sportName)
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                if let team = sport.teamName {
                    Text(team)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                let classCount = dataService.getClasses(for: child.id).filter { $0.sportId == sport.id }.count
                Text("\(classCount) scheduled sessions")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Menu {
                Button(action: { showEditSheet = true }) {
                    Label("Edit Sport", systemImage: "pencil")
                }
                Button(role: .destructive, action: { showDeleteAlert = true }) {
                    Label("Delete Sport", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.championBlue)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .sheet(isPresented: $showEditSheet) {
            EditSportView(sport: $editableSport)
        }
        .alert("Delete Sport", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dataService.deleteSport(id: sport.id)
            }
        } message: {
            Text("Are you sure you want to delete \(sport.sportName)? This will also delete all scheduled sessions for this sport.")
        }
    }
}

struct EditSportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @Binding var sport: Sport

    @State private var sportName = ""
    @State private var teamName = ""
    @State private var coachName = ""
    @State private var coachContact = ""
    @State private var location = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Sport Details") {
                    TextField("Sport Name", text: $sportName)
                    TextField("Team Name (optional)", text: $teamName)
                }

                Section("Coach Information") {
                    TextField("Coach Name", text: $coachName)
                    TextField("Coach Contact", text: $coachContact)
                        .keyboardType(.phonePad)
                }

                Section("Location") {
                    TextField("Practice/Game Location", text: $location)
                }
            }
            .navigationTitle("Edit Sport")
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
                    .disabled(sportName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadSportData()
            }
        }
    }

    private func loadSportData() {
        sportName = sport.sportName
        teamName = sport.teamName ?? ""
        coachName = sport.coachName ?? ""
        coachContact = sport.coachContact ?? ""
        location = sport.location ?? ""
    }

    private func saveChanges() {
        sport.sportName = sportName
        sport.teamName = teamName.isEmpty ? nil : teamName
        sport.coachName = coachName.isEmpty ? nil : coachName
        sport.coachContact = coachContact.isEmpty ? nil : coachContact
        sport.location = location.isEmpty ? nil : location

        dataService.updateSport(sport)
        dismiss()
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            height = y + lineHeight
        }
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
        allergies: ["Peanuts", "Shellfish"],
        totalPoints: 350,
        currentLevel: 4
    )

    NavigationStack {
        ChildDetailView(child: mockChild)
            .environmentObject(DataService())
    }
}
