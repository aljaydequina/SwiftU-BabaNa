import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @State private var confirmLogout = false
    @State private var testScheduled = false

    var body: some View {
        Form {
            Section("Account") {
                if let name = authService.user?.displayName, !name.isEmpty { Text(name) }
                Text(authService.user?.email ?? "Signed in")
                Button("Log Out", role: .destructive) { confirmLogout = true }
                if !authService.errorMessage.isEmpty { Text(authService.errorMessage).foregroundStyle(.red) }
            }
            Section {
                Toggle("Alert Sound", isOn: $soundEnabled)
                Toggle("Vibrate While App Is Open", isOn: $vibrationEnabled)
            } header: { Text("Trip Alerts") } footer: {
                Text("Lock-screen vibration, sound, and notification visibility follow your iPhone's notification, silent mode, and Focus settings.")
            }
            Section("Permissions") {
                LabeledContent("Location", value: locationManager.isAuthorized ? "Allowed" : "Not allowed")
                LabeledContent("Precise Location", value: locationManager.reducedAccuracy ? "Off" : "On")
                LabeledContent("Notifications", value: notificationManager.isAuthorized ? "Allowed" : "Not allowed")
                Button("Request Location Access") { locationManager.requestPermission() }
                Button("Request Notification Access") { notificationManager.requestPermission() }
                Button("Open iPhone Settings") { openSettings() }
            }
            Section {
                Button("Test Notification in 5 Seconds") {
                    notificationManager.sendTestNotification()
                    testScheduled = true
                }.disabled(!notificationManager.isAuthorized)
                if testScheduled {
                    Text("A test was requested. Lock your screen now to check delivery.").font(.caption)
                }
                if let error = notificationManager.errorMessage { Text(error).foregroundStyle(.red) }
            }
            Section("About") {
                LabeledContent("App", value: "BabaNa")
                LabeledContent("Version", value: "0.6")
                Text("Trips and saved stops are stored on this iPhone separately for each account. They are not synced between devices.")
                    .font(.caption)
                Text("Distances are straight-line estimates. Keep BabaNa running during a trip; force-quitting stops reminders.")
                    .font(.caption)
            }
        }
        .navigationTitle("Settings")
        .onAppear { notificationManager.refreshAuthorization(); locationManager.refreshAuthorization() }
        .alert("Log out?", isPresented: $confirmLogout) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) { authService.logout() }
        } message: {
            Text(appState.isTripActive ? "Your current trip will end and its reminders will stop." : "Your saved trips and stops will stay on this iPhone.")
        }
    }
}
