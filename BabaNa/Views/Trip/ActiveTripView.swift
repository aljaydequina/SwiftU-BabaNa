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
            VStack(spacing: 22) {
                if let trip = appState.activeTrip {
                    Map {
                        Marker(trip.destination.name, coordinate: trip.destination.coordinate).tint(BabaNaTheme.green)
                        UserAnnotation()
                    }.frame(height: 240).clipShape(RoundedRectangle(cornerRadius: 24))
                    VStack(spacing: 14) {
                        Label("TRIP IN PROGRESS", systemImage: "location.fill")
                            .font(.caption.bold()).tracking(1).foregroundStyle(BabaNaTheme.green)
                        Text(trip.destination.name).font(.title2.bold()).multilineTextAlignment(.center)
                        TimelineView(.periodic(from: .now, by: 5)) { _ in
                            let distance = locationManager.distance(to: trip.destination)
                            Text(distance.map { TripRules.distanceText($0) } ?? "Locating…")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .contentTransition(.numericText()).foregroundStyle(BabaNaTheme.green)
                            Text(distance == nil ? "Waiting for an accurate GPS position" : "Straight-line distance to your stop")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Divider()
                        LabeledContent("Remind me within", value: TripRules.distanceText(trip.reminderMeters))
                            .font(.subheadline)
                        LabeledContent("Started at", value: trip.startedAt.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline)
                    }.frame(maxWidth: .infinity).babaCard()
                    if trip.didSendApproachingAlert {
                        InfoBanner(text: "Your approaching reminder was sent. Get ready for your stop.", icon: "bell.badge.fill")
                    }
                    if locationManager.reducedAccuracy { LocationPermissionCard() }
                    if let error = locationManager.locationError { InfoBanner(text: error, icon: "location.slash") }
                    if !notificationManager.isAuthorized {
                        VStack(alignment: .leading, spacing: 12) {
                            InfoBanner(text: "Notifications are off. Turn them on to receive trip reminders.", icon: "bell.slash")
                            Button("Enable notifications") { notificationManager.requestPermission() }.buttonStyle(.bordered)
                        }
                    }
                    if let error = notificationManager.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
                    Label("You can lock your screen. Keep BabaNa running; swiping it away stops monitoring.", systemImage: "lock.shield")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("End trip", role: .destructive) { confirmEnd = true }
                        .buttonStyle(.bordered).frame(minHeight: 48)
                } else if let destination = appState.arrivalDestination {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 72)).foregroundStyle(BabaNaTheme.green).padding(.top, 40)
                    Text("Baba na!").font(.largeTitle.bold())
                    Text("You are near \(destination.name). Check your stop before getting off.").multilineTextAlignment(.center)
                    Text("Your trip is saved in History.").font(.subheadline).foregroundStyle(.secondary)
                    Button("Done") { dismiss() }.buttonStyle(BabaNaPrimaryButtonStyle())
                } else {
                    ContentUnavailableView("Trip ended", systemImage: "bus", description: Text("No reminder is currently active."))
                    Button("Back") { dismiss() }.buttonStyle(BabaNaPrimaryButtonStyle())
                }
            }.padding(20).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }
        .background(BabaNaTheme.background)
        .navigationTitle("Your ride").navigationBarTitleDisplayMode(.inline)
        .alert("End this trip?", isPresented: $confirmEnd) {
            Button("Keep trip", role: .cancel) { }
            Button("End trip", role: .destructive) { monitor.cancel(); dismiss() }
        } message: { Text("Location monitoring and reminders for this trip will stop.") }
    }
}
