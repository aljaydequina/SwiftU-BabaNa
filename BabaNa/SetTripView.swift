import SwiftUI
import MapKit
import UIKit

struct SetTripView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var monitor: TripMonitor
    let destination: Destination
    @State private var selectedDistance = 1000.0
    @State private var showActiveTrip = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Destination") {
                DestinationRow(destination: destination, icon: "mappin.circle.fill")
                Map {
                    Marker(destination.name, coordinate: destination.coordinate)
                }.frame(height: 180)
                Text("Check that this pin is your actual drop-off point before starting.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Remind me within") {
                Picker("Distance", selection: $selectedDistance) {
                    Text("500 m").tag(500.0)
                    Text("1 km").tag(1000.0)
                    Text("2 km").tag(2000.0)
                    if ![500.0, 1000.0, 2000.0].contains(selectedDistance) {
                        Text(TripRules.distanceText(selectedDistance)).tag(selectedDistance)
                    }
                }
                Slider(value: $selectedDistance, in: 200...5000, step: 100)
                Text("Selected: \(TripRules.distanceText(selectedDistance))")
                Text("Distance is measured in a straight line, not along the road. Arrival is within 150 m of the pin.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if !locationManager.isAuthorized || !notificationManager.isAuthorized {
                Section("Permissions needed") {
                    if !locationManager.isAuthorized {
                        Button("Allow Location") { locationManager.requestPermission() }
                    }
                    if !notificationManager.isAuthorized {
                        Button("Allow Notifications") { notificationManager.requestPermission() }
                    }
                    Button("Open iPhone Settings") { openSettings() }
                }
            }
            if locationManager.reducedAccuracy {
                Section {
                    Text("Enable Precise Location in iPhone Settings so reminders can work near your stop.")
                    Button("Open iPhone Settings") { openSettings() }
                }
            }
            Section {
                if appState.isTripActive {
                    NavigationLink("Return to active trip") { ActiveTripView() }
                    Text("End your current trip before starting another.").font(.caption)
                } else {
                    Button("Start Trip") {
                        errorMessage = monitor.start(destination: destination, reminderMeters: selectedDistance)
                        if errorMessage == nil { showActiveTrip = true }
                    }
                    .disabled(!locationManager.isAuthorized || !notificationManager.isAuthorized || locationManager.reducedAccuracy)
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            } footer: {
                Text("Keep BabaNa running during your trip. Do not swipe it away. GPS and notification delivery depend on your iPhone's settings and signal.")
            }
        }
        .navigationTitle("Set Trip")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showActiveTrip) { ActiveTripView() }
        .onAppear { notificationManager.refreshAuthorization(); locationManager.refreshAuthorization() }
    }
}

func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
}
