import SwiftUI
import MapKit

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 13.9430, longitude: 121.6120),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                NavigationLink {
                    SearchDestinationView()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        Text("Search destination")
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Map(position: $cameraPosition) {
                    if let coordinate = locationManager.currentLocation?.coordinate {
                        Annotation("You", coordinate: coordinate) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 15, height: 15)
                                .overlay(Circle().stroke(.white, lineWidth: 3))
                        }
                    }
                }
                .frame(height: 205)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .onAppear {
                    locationManager.startUpdatingLocation()
                }

                sectionTitle("Recent Destinations")

                VStack(spacing: 0) {
                    ForEach(Array(Destination.samples.prefix(3).enumerated()), id: \.element.id) { index, destination in
                        NavigationLink {
                            SetTripView(destination: destination)
                        } label: {
                            DestinationRow(destination: destination, icon: "clock")
                        }
                        .buttonStyle(.plain)

                        if index < 2 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                HStack {
                    sectionTitle("Saved Stops")
                    Spacer()

                    NavigationLink("See all") {
                        SavedStopsView()
                    }
                    .font(.caption.weight(.semibold))
                }

                HStack(spacing: 12) {
                    ForEach(appState.savedStops.prefix(2)) { stop in
                        NavigationLink {
                            SetTripView(destination: stop.destination)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: stop.icon)
                                    .font(.title3)
                                    .foregroundStyle(BabaNaTheme.green)

                                Text(stop.label)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(stop.destination.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
                            .padding(14)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(BabaNaTheme.background)
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("GOOD MORNING")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(BabaNaTheme.green)

                Text("Where are you\ngetting off?")
                    .font(.system(size: 29, weight: .bold))
                    .tracking(-0.4)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "bell")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(Circle())
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
    }
}

struct DestinationRow: View {
    let destination: Destination
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(BabaNaTheme.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(destination.name)
                    .font(.subheadline.weight(.semibold))

                Text(destination.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}
