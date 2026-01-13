import SwiftUI

@main
struct ChampTrackApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var dataService = DataService()

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
                    .environmentObject(authService)
                    .environmentObject(dataService)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}
