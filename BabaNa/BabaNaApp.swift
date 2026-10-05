import SwiftUI
import FirebaseCore
import Combine

final class AppServices: ObservableObject {
    let appState: AppState
    let auth: AuthService
    let location: LocationManager
    let notifications: NotificationManager
    let monitor: TripMonitor

    init() {
        // Configure before constructing AuthService, rather than racing AppDelegate startup.
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        appState = AppState()
        auth = AuthService()
        location = LocationManager()
        notifications = NotificationManager()
        monitor = TripMonitor(appState: appState, location: location, notifications: notifications)
    }
}

@main
struct BabaNaApp: App {
    @StateObject private var services = AppServices()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(services.appState)
                .environmentObject(services.auth)
                .environmentObject(services.location)
                .environmentObject(services.notifications)
                .environmentObject(services.monitor)
        }
    }
}
