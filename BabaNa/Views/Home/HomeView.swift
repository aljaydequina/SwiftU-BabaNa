import SwiftUI
import MapKit
import CoreLocation

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @State private var camera: MapCameraPosition = .region(DestinationSearch.philippines)
    @State private var didCenter = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                if let notice = appState.notice { InfoBanner(text: notice) }
                if let error = appState.storageError { InfoBanner(text: error, icon: "externaldrive.badge.exclamationmark") }
                if let trip = appState.activeTrip {
                    NavigationLink { ActiveTripView() } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "location.fill").font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TRIP IN PROGRESS").font(.caption2.bold()).tracking(1)
                                Text(trip.destination.name).font(.headline)
                                Text("Tap to view your reminder").font(.caption)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }.foregroundStyle(BabaNaTheme.green).babaCard()
                    }.buttonStyle(.plain)
                } else if let destination = appState.arrivalDestination {
                    InfoBanner(text: "You arrived near \(destination.name). Your trip is saved.", icon: "checkmark.circle.fill")
                }
                if !locationManager.isAuthorized || locationManager.reducedAccuracy {
                    LocationPermissionCard()
                }
                mapCard
                savedStops
                recentStops
                Label("Set a stop. Enjoy the ride. We'll remind you nearby.", systemImage: "bell.badge")
                    .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.bottom, 10)
            }.padding(20).frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
        }
        .background(BabaNaTheme.background)
        .navigationTitle("BabaNa").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "bus.fill").foregroundStyle(BabaNaTheme.green).accessibilityHidden(true)
            }
        }
        .task { locationManager.requestCurrentLocation() }
        .onReceive(locationManager.$currentLocation) { fix in
            guard let fix, !didCenter else { return }
            center(on: fix.coordinate)
            didCenter = true
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("YOUR COMMUTE COMPANION", systemImage: "sparkle")
                .font(.caption2.bold()).tracking(1.6).foregroundStyle(.white.opacity(0.75))
            Text("Saan ka bababa?").font(.largeTitle.bold()).foregroundStyle(.white)
            Text("Pick your stop. Get a heads-up before you arrive.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.8))
            NavigationLink { SearchDestinationView() } label: {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                    Text("Search your destination").font(.subheadline.weight(.semibold))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                }.foregroundStyle(BabaNaTheme.forest).padding(17)
                    .background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
            }.buttonStyle(.plain)
        }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [BabaNaTheme.forest, Color(red: 0.09, green: 0.40, blue: 0.29)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private var mapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Around you").font(.headline)
                Spacer()
                if locationManager.isLocating { ProgressView().controlSize(.small) }
                Text(locationManager.currentLocation == nil ? "Waiting for location" : "Map preview")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Map(position: $camera) { UserAnnotation() }
                .frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        if let fix = locationManager.currentLocation { center(on: fix.coordinate) }
                        else { locationManager.requestPermission() }
                    } label: {
                        Image(systemName: "location.fill").padding(14).background(.regularMaterial, in: Circle())
                    }.padding(10).accessibilityLabel("Center map on my location")
                }
            if locationManager.isAuthorized, let error = locationManager.locationError {
                Text(error).font(.caption).foregroundStyle(.secondary)
                Button("Retry location") { locationManager.requestCurrentLocation() }.font(.subheadline)
            }
        }
    }

    private var savedStops: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your usual stops").font(.headline)
                Spacer()
                NavigationLink("See all") { SavedStopsView() }.font(.subheadline.weight(.semibold))
            }
            if appState.savedStops.isEmpty {
                NavigationLink { SavedStopsView() } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "plus.circle.fill").font(.title).foregroundStyle(BabaNaTheme.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Make your next ride easier").font(.subheadline.bold()).foregroundStyle(.primary)
                            Text("Save your home, school, or usual stop.").font(.caption).foregroundStyle(.secondary)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).babaCard()
                }.buttonStyle(.plain)
            } else {
                VStack(spacing: 0) {
                    ForEach(appState.savedStops.prefix(3)) { stop in
                        NavigationLink { SetTripView(destination: stop.destination) } label: {
                            HStack(spacing: 14) {
                                Image(systemName: stop.icon).foregroundStyle(BabaNaTheme.green)
                                    .frame(width: 44, height: 44).background(BabaNaTheme.softGreen, in: RoundedRectangle(cornerRadius: 14))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stop.label).font(.subheadline.bold()).foregroundStyle(.primary)
                                    Text(stop.destination.name).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                            }.padding(.vertical, 8)
                        }.buttonStyle(.plain)
                    }
                }.babaCard()
            }
        }
    }

    private var recentStops: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent destinations").font(.headline)
            if appState.recentDestinations.isEmpty {
                Text("Your destinations will appear here after your first trip.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).babaCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(appState.recentDestinations.prefix(5)) { destination in
                        NavigationLink { SetTripView(destination: destination) } label: {
                            DestinationRow(destination: destination, icon: "clock")
                        }.buttonStyle(.plain)
                    }
                }.babaCard()
            }
        }
    }

    private func center(on coordinate: CLLocationCoordinate2D) {
        camera = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000))
    }
}

struct DestinationRow: View {
    let destination: Destination
    let icon: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(BabaNaTheme.green)
                .frame(width: 42, height: 42).background(BabaNaTheme.softGreen, in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 4) {
                Text(destination.name).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                if !destination.subtitle.isEmpty {
                    Text(destination.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 10).contentShape(Rectangle())
    }
}
