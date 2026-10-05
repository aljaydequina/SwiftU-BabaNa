import SwiftUI
import MapKit
import Combine

@MainActor
final class DestinationSearch: ObservableObject {
    @Published var results: [Destination] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    private var requestID = UUID()
    private var search: MKLocalSearch?

    func run(query: String, near coordinate: CLLocationCoordinate2D?) async {
        let id = UUID()
        requestID = id
        search?.cancel()
        results = []
        errorMessage = nil
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { isSearching = false; return }
        isSearching = true
        defer { if requestID == id { isSearching = false } }
        do {
            try await Task.sleep(nanoseconds: 350_000_000)
            try Task.checkCancellation()
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.resultTypes = [.address, .pointOfInterest]
            if let coordinate {
                request.region = MKCoordinateRegion(center: coordinate,
                                                     latitudinalMeters: 50000, longitudinalMeters: 50000)
            }
            let operation = MKLocalSearch(request: request)
            search = operation
            let response = try await operation.start()
            try Task.checkCancellation()
            guard requestID == id else { return }
            results = response.mapItems.compactMap { item in
                let coordinate = item.placemark.coordinate
                let place = Destination(name: item.name ?? query,
                                         subtitle: item.placemark.title ?? "",
                                         latitude: coordinate.latitude, longitude: coordinate.longitude)
                return place.isValid ? place : nil
            }
        } catch {
            guard requestID == id, !Task.isCancelled else { return }
            errorMessage = "Could not search places. Check your internet connection and try again."
        }
    }
}

struct DestinationSearchView: View {
    var onSelect: ((Destination) -> Void)? = nil
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var search = DestinationSearch()
    @State private var query = ""
    @State private var retry = 0

    var body: some View {
        List {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                if !appState.recentDestinations.isEmpty {
                    Section("Recent destinations") { rows(appState.recentDestinations) }
                }
                if !appState.savedStops.isEmpty {
                    Section("Saved destinations") { rows(savedDestinations) }
                }
                Text("Search a terminal, mall, school, or address. Include the city for better results.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else if search.isSearching {
                ProgressView("Searching places...")
            } else if let error = search.errorMessage {
                Text(error).foregroundStyle(.secondary)
                Button("Try again") { retry += 1 }
            } else if search.results.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                Section("Search results") { rows(search.results) }
            }
        }
        .navigationTitle("Choose Destination")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Place or address")
        .task(id: "\(query)|\(retry)") {
            await search.run(query: query, near: locationManager.currentLocation?.coordinate)
        }
    }

    private var savedDestinations: [Destination] {
        var seen = Set<UUID>()
        return appState.savedStops.map(\.destination).filter { seen.insert($0.id).inserted }
    }

    @ViewBuilder private func rows(_ destinations: [Destination]) -> some View {
        ForEach(destinations) { destination in
            if let onSelect {
                Button { onSelect(destination) } label: {
                    DestinationRow(destination: destination, icon: "mappin.and.ellipse")
                }.buttonStyle(.plain)
            } else {
                NavigationLink { SetTripView(destination: destination) } label: {
                    DestinationRow(destination: destination, icon: "mappin.and.ellipse")
                }
            }
        }
    }
}
