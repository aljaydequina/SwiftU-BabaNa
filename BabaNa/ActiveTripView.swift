import SwiftUI
import MapKit
import CoreLocation

struct ActiveTripView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showEndTripAlert = false
    @State private var showArrivalScreen = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let destination = appState.selectedDestination {
                    Map(position: $cameraPosition) {
                        Marker(destination.name, coordinate: destination.coordinate)

                        if let currentCoordinate = locationManager.currentLocation?.coordinate {
                            Annotation("You", coordinate: currentCoordinate) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(.white, lineWidth: 3))
                            }
                        }
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    HStack(spacing: 10) {
                        infoBox(title: "Distance", value: distanceText)
                        infoBox(title: "Reminder", value: reminderText)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(BabaNaTheme.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Trip reminder")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("Monitoring your location")
                                .font(.subheadline.weight(.semibold))
                        }

                        Spacer()

                        Text("ACTIVE")
                            .font(.caption2.bold())
                            .foregroundStyle(BabaNaTheme.green)
                    }
                    .padding(15)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(spacing: 0) {
                        detailRow(icon: "clock", title: "Started", value: appState.tripStartDate?.formatted(date: .omitted, time: .shortened) ?? "--")
                        Divider().padding(.leading, 48)
                        detailRow(icon: "location.fill", title: "GPS", value: locationManager.currentLocation == nil ? "Finding location..." : "Tracking")
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button {
                        notificationManager.sendApproachingNotification(
                            destination: destination.name,
                            distanceText: reminderText
                        )
                    } label: {
                        Label("Test Notification", systemImage: "bell.badge")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .foregroundStyle(BabaNaTheme.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(role: .destructive) {
                        showEndTripAlert = true
                    } label: {
                        Text("End Trip")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.08))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(18)
        }
        .background(BabaNaTheme.background)
        .navigationTitle("Active Trip")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear { locationManager.startUpdatingLocation() }
        .onDisappear {
            if !appState.isTripActive {
                locationManager.stopUpdatingLocation()
            }
        }
        .onReceive(locationManager.$currentLocation) { _ in
            checkDistanceAndNotify()
        }
        .alert("End this trip?", isPresented: $showEndTripAlert) {
            Button("Cancel", role: .cancel) {}
            Button("End Trip", role: .destructive) {
                appState.endTrip(status: .cancelled)
                dismiss()
            }
        } message: {
            Text("Your active reminder will stop.")
        }
        .sheet(isPresented: $showArrivalScreen) {
            ArrivalView()
        }
    }

    private var distanceMeters: Double? {
        guard let destination = appState.selectedDestination else { return nil }
        return locationManager.distance(to: destination)
    }

    private var distanceText: String {
        guard let meters = distanceMeters else { return "Locating..." }
        if meters < 1000 { return "\(Int(meters)) m" }
        return String(format: "%.1f km", meters / 1000)
    }

    private var reminderText: String {
        let meters = appState.selectedReminderDistance
        if meters < 1000 { return "\(Int(meters)) m" }
        return String(format: "%.1f km", meters / 1000)
    }

    private func checkDistanceAndNotify() {
        guard appState.isTripActive,
              let destination = appState.selectedDestination,
              let meters = distanceMeters else { return }

        if meters <= appState.selectedReminderDistance &&
           !appState.didSendApproachingAlert {
            appState.didSendApproachingAlert = true
            notificationManager.sendApproachingNotification(
                destination: destination.name,
                distanceText: reminderText
            )
        }

        if meters <= 150 &&
           !appState.didSendArrivalAlert {
            appState.didSendArrivalAlert = true
            notificationManager.sendArrivalNotification(destination: destination.name)
            showArrivalScreen = true
        }
    }

    private func infoBox(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(BabaNaTheme.green)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(15)
    }
}

struct ArrivalView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 86))
                .foregroundStyle(BabaNaTheme.green)

            Text("You have arrived")
                .font(.largeTitle.bold())

            Text(appState.selectedDestination?.name ?? "Destination")
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                appState.endTrip(status: .completed)
                dismiss()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(BabaNaTheme.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(22)
        .background(BabaNaTheme.background)
    }
}
