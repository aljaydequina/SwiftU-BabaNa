import SwiftUI
import MapKit
import CoreLocation

struct MapDestinationPicker: View {
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Destination) -> Void
    @State private var camera: MapCameraPosition = .region(DestinationSearch.philippines)
    @State private var coordinate = DestinationSearch.philippines.center
    @State private var name = ""

    var body: some View {
        VStack(spacing: 0) {
            Text("Move and zoom the map to put your stop under the pin.")
                .font(.subheadline).foregroundStyle(.secondary).padding()
            Map(position: $camera) { UserAnnotation() }
                .mapStyle(.standard(elevation: .flat))
                .onMapCameraChange(frequency: .continuous) { context in coordinate = context.region.center }
                .overlay {
                    Image(systemName: "mappin")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(BabaNaTheme.forest)
                        .shadow(color: .white, radius: 2)
                        .offset(y: -22).allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        if let fix = locationManager.currentLocation {
                            camera = .region(MKCoordinateRegion(center: fix.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000))
                        } else { locationManager.requestPermission() }
                    } label: {
                        Image(systemName: "location.fill").padding(14).background(.regularMaterial, in: Circle())
                    }.padding().accessibilityLabel("Center map on my location")
                }
            VStack(alignment: .leading, spacing: 12) {
                Text("Name this stop").font(.headline)
                TextField("e.g. School gate or bus stop", text: $name)
                    .textFieldStyle(.roundedBorder).submitLabel(.done)
                Text("Check the pin carefully. This exact point will be used for your reminder.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Use this stop") {
                    let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let subtitle = String(format: "Pinned location · %.5f, %.5f", coordinate.latitude, coordinate.longitude)
                    onSelect(Destination(name: title.isEmpty ? "Pinned stop" : title, subtitle: subtitle,
                                         latitude: coordinate.latitude, longitude: coordinate.longitude))
                }.buttonStyle(BabaNaPrimaryButtonStyle())
            }.padding(20).background(BabaNaTheme.card)
        }
        .background(BabaNaTheme.background)
        .navigationTitle("Choose on map").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .onAppear {
            if let fix = locationManager.currentLocation {
                coordinate = fix.coordinate
                camera = .region(MKCoordinateRegion(center: fix.coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000))
            }
        }
    }
}
