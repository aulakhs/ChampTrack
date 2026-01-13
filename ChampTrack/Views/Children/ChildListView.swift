import SwiftUI

struct ChildListView: View {
    @EnvironmentObject var dataService: DataService
    @State private var showAddChild = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if dataService.children.isEmpty {
                    EmptyStateCard(
                        icon: "person.badge.plus",
                        title: "No children added",
                        subtitle: "Add your first child to get started"
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(dataService.children) { child in
                        NavigationLink(destination: ChildDetailView(child: child)) {
                            ChildCard(child: child)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.softBackground)
        .navigationTitle("Children")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddChild = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.championBlue)
                }
            }
        }
        .sheet(isPresented: $showAddChild) {
            AddChildView()
        }
    }
}

struct AddChildView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -8, to: Date())!
    @State private var gender: Gender = .male
    @State private var weight = ""
    @State private var height = ""
    @State private var allergies: [String] = []
    @State private var newAllergy = ""
    @State private var schoolGrade = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)

                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { g in
                            Text(g.displayName).tag(g)
                        }
                    }
                }

                Section("Physical Information") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("kg", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                            .foregroundColor(.textSecondary)
                    }

                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("cm", text: $height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cm")
                            .foregroundColor(.textSecondary)
                    }
                }

                Section("Additional Information") {
                    TextField("School Grade (optional)", text: $schoolGrade)

                    ForEach(allergies, id: \.self) { allergy in
                        HStack {
                            Text(allergy)
                            Spacer()
                            Button(action: { allergies.removeAll { $0 == allergy } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }

                    HStack {
                        TextField("Add allergy", text: $newAllergy)
                        Button(action: addAllergy) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.championBlue)
                        }
                        .disabled(newAllergy.isEmpty)
                    }
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChild()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !weight.isEmpty && !height.isEmpty
    }

    private func addAllergy() {
        guard !newAllergy.isEmpty else { return }
        allergies.append(newAllergy)
        newAllergy = ""
    }

    private func saveChild() {
        let child = Child(
            familyId: dataService.family?.id ?? "",
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            gender: gender,
            weight: Double(weight) ?? 0,
            height: Double(height) ?? 0,
            allergies: allergies,
            schoolGrade: schoolGrade.isEmpty ? nil : schoolGrade
        )

        dataService.addChild(child)
        dismiss()
    }
}

struct EditChildView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @Binding var child: Child

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = Date()
    @State private var gender: Gender = .male
    @State private var weight = ""
    @State private var height = ""
    @State private var allergies: [String] = []
    @State private var newAllergy = ""
    @State private var schoolGrade = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)

                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { g in
                            Text(g.displayName).tag(g)
                        }
                    }
                }

                Section("Physical Information") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("kg", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                            .foregroundColor(.textSecondary)
                    }

                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("cm", text: $height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cm")
                            .foregroundColor(.textSecondary)
                    }
                }

                Section("Additional Information") {
                    TextField("School Grade (optional)", text: $schoolGrade)

                    ForEach(allergies, id: \.self) { allergy in
                        HStack {
                            Text(allergy)
                            Spacer()
                            Button(action: { allergies.removeAll { $0 == allergy } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }

                    HStack {
                        TextField("Add allergy", text: $newAllergy)
                        Button(action: addAllergy) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.championBlue)
                        }
                        .disabled(newAllergy.isEmpty)
                    }
                }
            }
            .navigationTitle("Edit Child")
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
                loadChildData()
            }
        }
    }

    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !weight.isEmpty && !height.isEmpty
    }

    private func loadChildData() {
        firstName = child.firstName
        lastName = child.lastName
        dateOfBirth = child.dateOfBirth
        gender = child.gender
        weight = String(format: "%.0f", child.weight)
        height = String(format: "%.0f", child.height)
        allergies = child.allergies
        schoolGrade = child.schoolGrade ?? ""
    }

    private func addAllergy() {
        guard !newAllergy.isEmpty else { return }
        allergies.append(newAllergy)
        newAllergy = ""
    }

    private func saveChanges() {
        child.firstName = firstName
        child.lastName = lastName
        child.dateOfBirth = dateOfBirth
        child.gender = gender
        child.weight = Double(weight) ?? child.weight
        child.height = Double(height) ?? child.height
        child.allergies = allergies
        child.schoolGrade = schoolGrade.isEmpty ? nil : schoolGrade

        dataService.updateChild(child)
        dismiss()
    }
}

#Preview {
    ChildListView()
        .environmentObject(DataService())
}
