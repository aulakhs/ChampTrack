import SwiftUI

struct AddActivityView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService

    @State private var selectedChild: Child?
    @State private var selectedSport: Sport?
    @State private var classType: ClassType = .practice
    @State private var date = Date()
    @State private var duration = 60
    @State private var locationName = ""
    @State private var locationAddress = ""
    @State private var recurringFrequency: RecurringFrequency = .none
    @State private var notes = ""
    @State private var equipmentNeeded: [String] = []
    @State private var newEquipment = ""

    var body: some View {
        NavigationStack {
            Form {
                // Child selection
                Section("Child") {
                    if dataService.children.isEmpty {
                        Text("No children added yet")
                            .foregroundColor(.textSecondary)
                    } else {
                        Picker("Select Child", selection: $selectedChild) {
                            Text("Select a child").tag(nil as Child?)
                            ForEach(dataService.children) { child in
                                Text(child.firstName).tag(child as Child?)
                            }
                        }
                    }
                }

                // Sport selection
                Section("Sport") {
                    if let child = selectedChild {
                        let childSports = dataService.getSports(for: child.id)

                        if childSports.isEmpty {
                            Text("No sports added for \(child.firstName)")
                                .foregroundColor(.textSecondary)

                            NavigationLink("Add Sport") {
                                AddSportView(preselectedChild: child)
                            }
                        } else {
                            Picker("Select Sport", selection: $selectedSport) {
                                Text("Select a sport").tag(nil as Sport?)
                                ForEach(childSports) { sport in
                                    HStack {
                                        Image(systemName: sport.iconName)
                                        Text(sport.sportName)
                                    }.tag(sport as Sport?)
                                }
                            }
                        }
                    } else {
                        Text("Select a child first")
                            .foregroundColor(.textSecondary)
                    }
                }

                // Activity details
                Section("Activity Details") {
                    Picker("Type", selection: $classType) {
                        ForEach(ClassType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                Text(type.displayName)
                            }.tag(type)
                        }
                    }

                    DatePicker("Date & Time", selection: $date)

                    Stepper("Duration: \(duration) minutes", value: $duration, in: 15...240, step: 15)
                }

                // Location
                Section("Location") {
                    TextField("Location Name", text: $locationName)
                    TextField("Address (optional)", text: $locationAddress)
                }

                // Recurring
                Section("Recurring") {
                    Picker("Frequency", selection: $recurringFrequency) {
                        ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                }

                // Equipment
                Section("Equipment Needed") {
                    ForEach(equipmentNeeded, id: \.self) { item in
                        HStack {
                            Text(item)
                            Spacer()
                            Button(action: { equipmentNeeded.removeAll { $0 == item } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }

                    HStack {
                        TextField("Add equipment", text: $newEquipment)
                        Button(action: addEquipment) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.championBlue)
                        }
                        .disabled(newEquipment.isEmpty)
                    }
                }

                // Notes
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveActivity()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var isFormValid: Bool {
        selectedChild != nil && selectedSport != nil
    }

    private func addEquipment() {
        guard !newEquipment.isEmpty else { return }
        equipmentNeeded.append(newEquipment)
        newEquipment = ""
    }

    private func saveActivity() {
        guard let child = selectedChild, let sport = selectedSport else { return }

        let location = locationName.isEmpty ? nil : Location(
            name: locationName,
            address: locationAddress.isEmpty ? nil : locationAddress
        )

        let sportClass = SportClass(
            sportId: sport.id,
            childId: child.id,
            familyId: child.familyId,
            type: classType,
            dateTime: date,
            duration: duration,
            location: location,
            recurringFrequency: recurringFrequency,
            notes: notes.isEmpty ? nil : notes,
            equipmentNeeded: equipmentNeeded
        )

        dataService.addClass(sportClass)
        dismiss()
    }
}

struct AddSportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService

    var preselectedChild: Child?

    @State private var selectedChild: Child?
    @State private var sportName = ""
    @State private var teamName = ""
    @State private var coachName = ""
    @State private var coachContact = ""
    @State private var location = ""
    @State private var seasonStart: Date?
    @State private var seasonEnd: Date?
    @State private var selectedColor = "4A90E2"
    @State private var showSeasonDates = false

    private let sportOptions = ["Soccer", "Basketball", "Swimming", "Baseball", "Football", "Tennis", "Volleyball", "Hockey", "Golf", "Gymnastics", "Track", "Dance", "Martial Arts", "Cycling", "Other"]

    var body: some View {
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

            // Sport details
            Section("Sport Details") {
                Picker("Sport", selection: $sportName) {
                    Text("Select a sport").tag("")
                    ForEach(sportOptions, id: \.self) { sport in
                        HStack {
                            Image(systemName: Sport.sportIcons[sport] ?? "sportscourt.fill")
                            Text(sport)
                        }.tag(sport)
                    }
                }

                TextField("Team Name (optional)", text: $teamName)
            }

            // Coach info
            Section("Coach Information") {
                TextField("Coach Name", text: $coachName)
                TextField("Coach Contact", text: $coachContact)
                    .keyboardType(.phonePad)
            }

            // Location
            Section("Location") {
                TextField("Practice/Game Location", text: $location)
            }

            // Season dates
            Section("Season") {
                Toggle("Set Season Dates", isOn: $showSeasonDates)

                if showSeasonDates {
                    DatePicker("Season Start", selection: Binding(
                        get: { seasonStart ?? Date() },
                        set: { seasonStart = $0 }
                    ), displayedComponents: .date)

                    DatePicker("Season End", selection: Binding(
                        get: { seasonEnd ?? Calendar.current.date(byAdding: .month, value: 3, to: Date())! },
                        set: { seasonEnd = $0 }
                    ), displayedComponents: .date)
                }
            }

            // Color
            Section("Color") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(Sport.sportColors.values), id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .shadow(color: selectedColor == color ? Color(hex: color).opacity(0.5) : .clear, radius: 4)
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Add Sport")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveSport()
                }
                .disabled(!isFormValid)
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            if let child = preselectedChild {
                selectedChild = child
            }
        }
    }

    private var isFormValid: Bool {
        let child = preselectedChild ?? selectedChild
        return child != nil && !sportName.isEmpty
    }

    private func saveSport() {
        guard let child = preselectedChild ?? selectedChild else { return }

        let iconName = Sport.sportIcons[sportName] ?? "sportscourt.fill"
        let color = Sport.sportColors[sportName] ?? selectedColor

        let sport = Sport(
            childId: child.id,
            familyId: child.familyId,
            sportName: sportName,
            teamName: teamName.isEmpty ? nil : teamName,
            coachName: coachName.isEmpty ? nil : coachName,
            coachContact: coachContact.isEmpty ? nil : coachContact,
            seasonStart: showSeasonDates ? seasonStart : nil,
            seasonEnd: showSeasonDates ? seasonEnd : nil,
            location: location.isEmpty ? nil : location,
            colorHex: color,
            iconName: iconName
        )

        dataService.addSport(sport)
        dismiss()
    }
}

#Preview {
    AddActivityView()
        .environmentObject(DataService())
}
