import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var dataService: DataService
    @State private var selectedDate = Date()
    @State private var viewMode: ViewMode = .week
    @State private var selectedChild: String? = nil
    @State private var showAddActivity = false

    enum ViewMode: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View mode picker
                Picker("View", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Child filter
                if !dataService.children.isEmpty {
                    childFilter
                }

                // Calendar/List content
                ScrollView {
                    VStack(spacing: 16) {
                        // Date navigation
                        dateNavigator

                        // Content based on view mode
                        switch viewMode {
                        case .day:
                            dayView
                        case .week:
                            weekView
                        case .month:
                            monthView
                        }
                    }
                    .padding()
                }
            }
            .background(Color.softBackground)
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddActivity = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.championBlue)
                    }
                }
            }
            .sheet(isPresented: $showAddActivity) {
                AddActivityView()
            }
        }
    }

    // MARK: - Child Filter

    private var childFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: selectedChild == nil,
                    onTap: { selectedChild = nil }
                )

                ForEach(dataService.children) { child in
                    FilterChip(
                        title: child.firstName,
                        isSelected: selectedChild == child.id,
                        onTap: { selectedChild = child.id }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Date Navigator

    private var dateNavigator: some View {
        HStack {
            Button(action: navigatePrevious) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.championBlue)
            }

            Spacer()

            Text(dateTitle)
                .font(.headline)
                .foregroundColor(.textPrimary)

            Spacer()

            Button(action: navigateNext) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.championBlue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .day:
            formatter.dateFormat = "EEEE, MMM d"
        case .week:
            formatter.dateFormat = "MMM d"
            let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? selectedDate
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "MMM d, yyyy"
            return "\(formatter.string(from: startOfWeek)) - \(endFormatter.string(from: endOfWeek))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        }
        return formatter.string(from: selectedDate)
    }

    private func navigatePrevious() {
        let calendar = Calendar.current
        switch viewMode {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    private func navigateNext() {
        let calendar = Calendar.current
        switch viewMode {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }
    }

    // MARK: - Day View

    private var dayView: some View {
        VStack(spacing: 12) {
            let classes = filteredClasses(for: selectedDate)

            if classes.isEmpty {
                EmptyStateCard(
                    icon: "calendar",
                    title: "No activities",
                    subtitle: "No activities scheduled for this day"
                )
            } else {
                ForEach(classes) { sportClass in
                    let sport = dataService.sports.first { $0.id == sportClass.sportId }
                    let child = dataService.getChild(id: sportClass.childId)

                    ActivityCard(
                        sportClass: sportClass,
                        sport: sport,
                        child: child
                    )
                }
            }
        }
    }

    // MARK: - Week View

    private var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        return calendar.date(from: components) ?? selectedDate
    }

    private var weekView: some View {
        VStack(spacing: 16) {
            // Week day headers
            HStack(spacing: 4) {
                ForEach(0..<7) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: startOfWeek) ?? selectedDate
                    WeekDayHeader(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate))
                        .onTapGesture {
                            selectedDate = date
                        }
                }
            }

            // Activities for selected day
            dayView
        }
    }

    // MARK: - Month View

    private var monthView: some View {
        VStack(spacing: 16) {
            // Calendar grid
            MonthCalendarGrid(
                selectedDate: $selectedDate,
                classes: dataService.classes,
                sports: dataService.sports
            )

            // Activities for selected day
            VStack(alignment: .leading, spacing: 8) {
                Text("Activities on \(selectedDateFormatted)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)

                dayView
            }
        }
    }

    private var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: selectedDate)
    }

    // MARK: - Helpers

    private func filteredClasses(for date: Date) -> [SportClass] {
        var classes = dataService.getClasses(for: date)

        if let childId = selectedChild {
            classes = classes.filter { $0.childId == childId }
        }

        return classes.sorted { $0.dateTime < $1.dateTime }
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.championBlue : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct WeekDayHeader: View {
    let date: Date
    let isSelected: Bool

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    var body: some View {
        VStack(spacing: 4) {
            Text(dayFormatter.string(from: date))
                .font(.caption)
                .foregroundColor(.textSecondary)

            Text(dateFormatter.string(from: date))
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .textPrimary)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.championBlue : Color.clear)
                .clipShape(Circle())
        }
        .frame(maxWidth: .infinity)
    }
}

struct MonthCalendarGrid: View {
    @Binding var selectedDate: Date
    let classes: [SportClass]
    let sports: [Sport]

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            // Day headers
            HStack {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar days
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasActivities: hasActivities(on: date),
                            activityColors: activityColors(on: date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Text("")
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    private var daysInMonth: [Date?] {
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let range = calendar.range(of: .day, in: .month, for: selectedDate)!

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    private func hasActivities(on date: Date) -> Bool {
        classes.contains { calendar.isDate($0.dateTime, inSameDayAs: date) }
    }

    private func activityColors(on date: Date) -> [Color] {
        let dayClasses = classes.filter { calendar.isDate($0.dateTime, inSameDayAs: date) }
        let sportIds = Set(dayClasses.map { $0.sportId })
        return sportIds.compactMap { id in
            sports.first { $0.id == id }?.color
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let hasActivities: Bool
    let activityColors: [Color]

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : (isToday ? .championBlue : .textPrimary))
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.championBlue : (isToday ? Color.championBlue.opacity(0.1) : Color.clear))
                .clipShape(Circle())

            // Activity indicators
            HStack(spacing: 2) {
                ForEach(activityColors.prefix(3), id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(height: 44)
    }
}

#Preview {
    ScheduleView()
        .environmentObject(DataService())
}
