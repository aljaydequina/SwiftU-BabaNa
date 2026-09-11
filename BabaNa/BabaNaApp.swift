import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        FirebaseApp.configure()
        return true
    }
}

@main
struct BabaNaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var delegate

    @StateObject private var appState = AppState()
    @StateObject private var authService = AuthService()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authService)
                .environmentObject(locationManager)
                .environmentObject(notificationManager)
        }
    }
}
