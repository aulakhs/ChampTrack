# ChampTrack

A native iOS app for parents to manage their children's sports activities, track nutrition, set goals, and gamify achievements.

## Features

### Family Management
- Add and manage multiple children profiles
- Track physical information (height, weight, allergies)
- View activity summaries and progress

### Sports & Schedule Management
- Add sports for each child (Soccer, Basketball, Swimming, etc.)
- Track team names, coaches, and locations
- View scheduled sessions and practices
- Calendar integration for scheduling

### Nutrition Tracking
- Log daily meals with photos
- Track calories, protein, carbs, and fats
- Visual progress charts and statistics
- Hydration tracking

### Goals & Gamification
- Create custom goals (sports, nutrition, attendance, personal)
- Track progress with visual indicators
- Set milestones and deadlines
- Earn points and level up
- Unlock achievements and trophies

### User Experience
- Clean, modern SwiftUI interface
- Tab-based navigation
- Edit and delete functionality for all entities
- Responsive design for all iPhone sizes

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

### Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/ChampTrack.git
cd ChampTrack
```

### Generate Xcode Project (if needed)

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation.

```bash
# Install XcodeGen if not already installed
brew install xcodegen

# Generate the Xcode project
xcodegen generate
```

### Open in Xcode

```bash
open ChampTrack.xcodeproj
```

### Running on Simulator

1. Select a simulator from the device dropdown (e.g., iPhone 15)
2. Press `Cmd + R` or click the Play button

### Running on Physical Device

To install ChampTrack on your iPhone:

1. **Apple Developer Account**: You need an Apple ID (free accounts work for personal use)

2. **Configure Signing in Xcode**:
   - Open `ChampTrack.xcodeproj` in Xcode
   - Select the `ChampTrack` target in the project navigator
   - Go to the "Signing & Capabilities" tab
   - Check "Automatically manage signing"
   - Select your Team (your Apple ID)
   - If you see a signing error, Xcode will prompt you to register your device

3. **Connect Your iPhone**:
   - Connect your iPhone via USB cable
   - Trust the computer on your iPhone if prompted
   - Select your iPhone from the device dropdown in Xcode

4. **Build and Run**:
   - Press `Cmd + R` or click the Play button
   - The app will install on your device

5. **Trust the Developer** (first time only):
   - On your iPhone, go to Settings > General > VPN & Device Management
   - Tap on your developer account
   - Tap "Trust" to allow apps from this developer

> **Note**: Free Apple Developer accounts have limitations:
> - Apps expire after 7 days and need to be reinstalled
> - Limited to 3 apps per device
> - No App Store distribution

## Project Structure

```
ChampTrack/
├── ChampTrackApp.swift          # App entry point
├── ContentView.swift            # Main tab view
├── Models/                      # Data models
│   ├── User.swift
│   ├── Family.swift
│   ├── Child.swift
│   ├── Sport.swift
│   ├── SportClass.swift
│   ├── Nutrition.swift
│   ├── Goal.swift
│   └── Achievement.swift
├── Views/                       # SwiftUI views
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── SignUpView.swift
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Schedule/
│   │   └── ScheduleView.swift
│   ├── Children/
│   │   ├── ChildListView.swift
│   │   └── ChildDetailView.swift
│   ├── Nutrition/
│   │   └── NutritionView.swift
│   ├── Goals/
│   │   └── GoalsView.swift
│   ├── Achievements/
│   │   └── AchievementsView.swift
│   └── Settings/
│       └── SettingsView.swift
├── ViewModels/                  # Business logic (MVVM)
├── Services/                    # Data & API services
│   ├── AuthService.swift
│   └── DataService.swift
├── Components/                  # Reusable UI components
│   ├── Cards/
│   │   ├── ChildCard.swift
│   │   ├── ActivityCard.swift
│   │   └── GoalCard.swift
│   ├── Buttons/
│   │   └── PrimaryButton.swift
│   └── Charts/
│       └── ProgressRing.swift
└── Extensions/                  # Swift extensions
    └── Color+Theme.swift
```

## Architecture

ChampTrack follows the **MVVM (Model-View-ViewModel)** architecture pattern:

- **Models**: Data structures representing app entities (Child, Sport, Goal, etc.)
- **Views**: SwiftUI views for the user interface
- **ViewModels**: Business logic and state management
- **Services**: Data persistence and API communication

### Data Layer

Currently uses mock data via `DataService` for demonstration. The architecture is designed to easily integrate with:
- Firebase Firestore
- Core Data
- CloudKit
- Any REST API

## Design System

### Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Champion Blue | `#4A90E2` | Primary actions, links |
| Victory Gold | `#F5A623` | Points, rewards |
| Energy Green | `#7ED321` | Success, health |
| Accent Purple | `#9B59B6` | Achievements |
| Accent Red | `#E74C3C` | Alerts, warnings |
| Soft Background | `#F8F9FA` | Page backgrounds |
| Text Primary | `#2C3E50` | Main text |
| Text Secondary | `#7F8C8D` | Secondary text |

### Typography

Uses system fonts with the following hierarchy:
- **Title**: Large titles for headers
- **Headline**: Section headers
- **Body**: Main content
- **Caption**: Secondary information

## Configuration

### Bundle Identifier

The default bundle identifier is `com.champtrack.app`. To change it:

1. Open `project.yml`
2. Update the `PRODUCT_BUNDLE_IDENTIFIER` setting
3. Regenerate the project with `xcodegen generate`

### App Icon

Add your app icon to `ChampTrack/Assets.xcassets/AppIcon.appiconset/`

## Future Enhancements

- [ ] Firebase integration for cloud sync
- [ ] Push notifications for reminders
- [ ] Apple Watch companion app
- [ ] Family sharing and multi-user support
- [ ] Export data to PDF/CSV
- [ ] Dark mode support
- [ ] Widgets for quick stats
- [ ] Siri shortcuts integration

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI
- Icons from SF Symbols
- Project generated with XcodeGen
