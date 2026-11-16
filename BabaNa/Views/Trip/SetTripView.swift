import SwiftUI
import UserNotifications
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

    private var canStart: Bool {
        locationManager.isAuthorized && notificationManager.isAuthorized && !locationManager.reducedAccuracy
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("YOUR DROP-OFF").font(.caption.bold()).tracking(1.4).foregroundStyle(BabaNaTheme.green)
                    Text(destination.name).font(.title2.bold())
                    Text(destination.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    Map {
                        Marker(destination.name, coordinate: destination.coordinate).tint(BabaNaTheme.green)
                    }.frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 18))
                    Label("Check that the pin marks your actual stop.", systemImage: "mappin.and.ellipse")
                        .font(.caption).foregroundStyle(.secondary)
                }.babaCard()
                reminderCard
                if !locationManager.isAuthorized || locationManager.reducedAccuracy { LocationPermissionCard() }
                if !notificationManager.isAuthorized {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Turn on trip notifications", systemImage: "bell.badge.fill").font(.headline)
                        Text("Receive your reminder while the screen is locked or another app is open.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Button(notificationManager.authorizationStatus == .denied ? "Open Settings" : "Allow Notifications") {
                            notificationManager.requestPermission()
                        }.buttonStyle(.bordered)
                        if let error = notificationManager.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
                    }.babaCard()
                }
                Label("Keep BabaNa running during your trip. Swiping it away stops reminders.", systemImage: "info.circle")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(20).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }
        .background(BabaNaTheme.background)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(.red) }
                if appState.isTripActive {
                    NavigationLink { ActiveTripView() } label: { Text("View active trip") }
                        .buttonStyle(BabaNaPrimaryButtonStyle())
                    Text("End your current trip before starting another.").font(.caption).foregroundStyle(.secondary)
                } else {
                    Button {
                        errorMessage = monitor.start(destination: destination, reminderMeters: selectedDistance)
                        if errorMessage == nil { showActiveTrip = true }
                    } label: { Label("Start trip", systemImage: "location.fill") }
                        .buttonStyle(BabaNaPrimaryButtonStyle()).disabled(!canStart)
                    if !canStart { Text("Enable location, precise location, and notifications above.").font(.caption).foregroundStyle(.secondary) }
                }
            }.padding(20).background(.regularMaterial)
        }
        .navigationTitle("Plan your ride").navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showActiveTrip) { ActiveTripView() }
        .onAppear { notificationManager.refreshAuthorization(); locationManager.refreshAuthorization() }
    }

    private var distancePresets: some View {
        HStack(spacing: 10) {
            distanceButton(500)
            distanceButton(1000)
            distanceButton(2000)
        }
    }

    private func distanceButton(_ distance: Double) -> some View {
        let isSelected = selectedDistance == distance
        let textColor: Color = isSelected ? .white : BabaNaTheme.green
        let backgroundColor: Color = isSelected ? BabaNaTheme.forest : BabaNaTheme.softGreen
        let traits: AccessibilityTraits = isSelected ? .isSelected : []

        return Button {
            selectedDistance = distance
        } label: {
            Text(TripRules.distanceText(distance))
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(textColor)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(traits)
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Remind me before my stop", systemImage: "bell.fill").font(.headline)
            Text(TripRules.distanceText(selectedDistance)).font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(BabaNaTheme.green).contentTransition(.numericText())
            distancePresets
            Slider(value: $selectedDistance, in: 200...5000, step: 100)
                .accessibilityLabel("Reminder distance").accessibilityValue(TripRules.distanceText(selectedDistance))
            HStack { Text("200 m"); Spacer(); Text("5 km") }.font(.caption).foregroundStyle(.secondary)
            Text("Distances are measured in a straight line, not along the road. The arrival alert is within 150 m of your pin.")
                .font(.caption).foregroundStyle(.secondary)
        }.babaCard()
    }
}

func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
}
