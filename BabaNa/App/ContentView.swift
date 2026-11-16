import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var monitor: TripMonitor
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if authService.isLoading {
                ProgressView("Loading...")
            } else if authService.user == nil {
                LoginView()
            } else if !appState.hasFinishedOnboarding {
                OnboardingView()
            } else {
                MainTabView().id(authService.user?.uid)
            }
        }
        .onChange(of: authService.user?.uid, initial: true) { _, id in
            monitor.accountDidChange()
            appState.loadAccount(id)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                locationManager.refreshAuthorization()
                notificationManager.refreshAuthorization()
            }
        }
    }
}
