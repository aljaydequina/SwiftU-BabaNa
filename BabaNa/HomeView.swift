import SwiftUI
import MapKit

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Where are you getting off?").font(.largeTitle.bold())
                if let notice = appState.notice {
                    Label(notice, systemImage: "exclamationmark.circle").font(.subheadline)
                }
                if let error = appState.storageError {
                    Label(error, systemImage: "externaldrive.badge.exclamationmark").foregroundStyle(.red)
                }
                if let trip = appState.activeTrip {
                    NavigationLink { ActiveTripView() } label: {
                        Label("Active trip: \(trip.destination.name)", systemImage: "location.fill")
                            .fontWeight(.semibold).frame(maxWidth: .infinity, alignment: .leading)
                            .padding().background(BabaNaTheme.softGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else if let destination = appState.arrivalDestination {
                    Label("You arrived near \(destination.name). Your trip has been saved.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(BabaNaTheme.green)
                }
                NavigationLink { SearchDestinationView() } label: {
                    Label("Search destination", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity, alignment: .leading).padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Map(position: $camera) { UserAnnotation() }
                    .frame(height: 210).clipShape(RoundedRectangle(cornerRadius: 16))
                Text("Recent Destinations").font(.headline)
                if appState.recentDestinations.isEmpty {
                    Text("Destinations will appear here after you start a trip.").foregroundStyle(.secondary)
                }
                ForEach(appState.recentDestinations.prefix(5)) { destination in
                    NavigationLink { SetTripView(destination: destination) } label: {
                        DestinationRow(destination: destination, icon: "clock")
                    }.buttonStyle(.plain)
                }
                HStack {
                    Text("Saved Stops").font(.headline)
                    Spacer()
                    NavigationLink("See all") { SavedStopsView() }
                }
                if appState.savedStops.isEmpty {
                    Text("Save your home, school, or usual stop from the Saved tab.").foregroundStyle(.secondary)
                }
                ForEach(appState.savedStops.prefix(3)) { stop in
                    NavigationLink { SetTripView(destination: stop.destination) } label: {
                        VStack(alignment: .leading) {
                            Label(stop.label, systemImage: stop.icon).font(.headline)
                            Text(stop.destination.name).font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding()
                    }.buttonStyle(.plain)
                }
            }.padding(18)
        }
        .background(BabaNaTheme.background)
        .navigationTitle("BabaNa")
        .navigationBarTitleDisplayMode(.inline)
        .task { locationManager.requestCurrentLocation() }
        .onReceive(locationManager.$currentLocation) { fix in
            guard let fix else { return }
            camera = .region(MKCoordinateRegion(center: fix.coordinate,
                                                latitudinalMeters: 3000, longitudinalMeters: 3000))
        }
    }
}

struct DestinationRow: View {
    let destination: Destination
    let icon: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(BabaNaTheme.green).frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(destination.name).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(destination.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }.padding(.vertical, 8)
    }
}
