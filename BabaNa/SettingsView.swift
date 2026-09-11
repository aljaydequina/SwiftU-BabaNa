import SwiftUI
import CoreLocation
import Combine

struct SettingsView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager

    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $vibrationEnabled) {
                    Label("Vibration", systemImage: "iphone.radiowaves.left.and.right")
                }

                Toggle(isOn: $soundEnabled) {
                    Label("Alert Sound", systemImage: "speaker.wave.2.fill")
                }
            } header: {
                Text("Trip Alerts")
            } footer: {
                Text("These options are part of the current midterm interface and can be expanded for the final version.")
            }

            Section("Permissions") {
                HStack {
                    Label("Location", systemImage: "location.fill")
                    Spacer()
                    Text(locationStatus)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Notifications", systemImage: "bell.fill")
                    Spacer()
                    Text(notificationManager.isAuthorized ? "Allowed" : "Not Set")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button("Request Location Permission") {
                    locationManager.requestPermission()
                }

                Button("Request Notification Permission") {
                    notificationManager.requestPermission()
                }
            }

            Section("About") {
                LabeledContent("App", value: "BabaNa")
                LabeledContent("Version", value: "Midterm 0.5")

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "location.circle.fill")
                        .foregroundStyle(BabaNaTheme.green)

                    Text("Uses CoreLocation to monitor distance during an active trip and can send a local stop reminder.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(BabaNaTheme.background)
        .navigationTitle("Settings")
    }

    private var locationStatus: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Allowed"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not Set"
        @unknown default:
            return "Unknown"
        }
    }
}
