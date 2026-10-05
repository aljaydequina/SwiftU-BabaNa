import SwiftUI
import MapKit

struct ActiveTripView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var monitor: TripMonitor
    @Environment(\.dismiss) private var dismiss
    @State private var confirmEnd = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let trip = appState.activeTrip {
                    Map {
                        Marker(trip.destination.name, coordinate: trip.destination.coordinate)
                        UserAnnotation()
                    }.frame(height: 280).clipShape(RoundedRectangle(cornerRadius: 16))
                    Text(trip.destination.name).font(.title2.bold())
                    TimelineView(.periodic(from: .now, by: 5)) { _ in
                        let distance = locationManager.distance(to: trip.destination)
                        Text(distance.map { TripRules.distanceText($0) } ?? "Waiting for accurate GPS...")
                            .font(.largeTitle.bold())
                        Text(distance == nil ? "Reminder monitoring is waiting for a usable location." : "Monitoring your distance")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    LabeledContent("Reminder", value: TripRules.distanceText(trip.reminderMeters))
                    LabeledContent("Started", value: trip.startedAt.formatted(date: .omitted, time: .shortened))
                    if trip.didSendApproachingAlert {
                        Label("Approaching reminder sent", systemImage: "bell.badge.fill")
                    }
                    if let error = locationManager.locationError { Text(error).foregroundStyle(.orange) }
                    if let error = notificationManager.errorMessage { Text(error).foregroundStyle(.red) }
                    Text("You can lock your screen or use another app. Keep BabaNa running; swiping it away stops monitoring.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("End Trip", role: .destructive) { confirmEnd = true }
                        .buttonStyle(.borderedProminent)
                } else if let destination = appState.arrivalDestination {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 72)).foregroundStyle(BabaNaTheme.green)
                    Text("Baba Na!").font(.largeTitle.bold())
                    Text("You are near \(destination.name). Check your stop before getting off.")
                    Text("Trip saved to your history.").foregroundStyle(.secondary)
                    Button("Done") { dismiss() }.buttonStyle(.borderedProminent)
                } else {
                    ContentUnavailableView("Trip ended", systemImage: "bus", description: Text("No reminder is currently active."))
                    Button("Back") { dismiss() }
                }
            }.padding(20)
        }
        .background(BabaNaTheme.background)
        .navigationTitle("Active Trip").navigationBarTitleDisplayMode(.inline)
        .alert("End this trip?", isPresented: $confirmEnd) {
            Button("Keep Trip", role: .cancel) { }
            Button("End Trip", role: .destructive) { monitor.cancel(); dismiss() }
        } message: { Text("Location monitoring and reminders for this trip will stop.") }
    }
}
