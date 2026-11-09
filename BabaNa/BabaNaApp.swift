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
            EmergencyAlertRootView()
                .environmentObject(services.appState)
                .environmentObject(services.auth)
                .environmentObject(services.location)
                .environmentObject(services.notifications)
                .environmentObject(services.monitor)
        }
    }
}

private struct EmergencyAlertRootView: View {
    @EnvironmentObject private var notifications: NotificationManager

    var body: some View {
        ZStack {
            ContentView()

            if let alert = notifications.emergencyAlert {
                Color.black.opacity(0.38)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)

                EmergencyAlertView(alert: alert) {
                    notifications.acknowledgeEmergency()
                }
                .frame(maxWidth: 390)
                .padding(.horizontal, 22)
                .transition(.scale(scale: 0.94).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.84), value: notifications.emergencyAlert?.id)
    }
}
