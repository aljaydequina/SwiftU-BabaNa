import SwiftUI
import MapKit
import CoreLocation
import Combine

@MainActor
final class DestinationSearch: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published private(set) var suggestions: [MKLocalSearchCompletion] = []
    @Published private(set) var results: [Destination] = []
    @Published private(set) var isSearching = false
    @Published private(set) var isSuggesting = false
    @Published private(set) var didSearch = false
    @Published private(set) var errorMessage: String?
    private var completer: MKLocalSearchCompleter?
    private var search: MKLocalSearch?
    private var generation = UUID()
    private var query = ""
    private var region = DestinationSearch.philippines

    // A search bias, not a restriction. Search also works without GPS permission.
    static let philippines = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 12.8797, longitude: 121.7740),
        span: MKCoordinateSpan(latitudeDelta: 18, longitudeDelta: 14))

    func update(query: String, near coordinate: CLLocationCoordinate2D?) {
        cancel()
        self.query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        region = coordinate.map { MKCoordinateRegion(center: $0, latitudinalMeters: 80000, longitudinalMeters: 80000) }
            ?? Self.philippines
        results = []
        suggestions = []
        didSearch = false
        errorMessage = nil
        guard self.query.count >= 2 else { return }
        let next = MKLocalSearchCompleter()
        next.delegate = self
        next.resultTypes = [.address, .pointOfInterest]
        next.region = region
        completer = next
        isSuggesting = true
        next.queryFragment = self.query
    }

    func cancel() {
        generation = UUID()
        search?.cancel()
        search = nil
        completer?.delegate = nil
        completer?.cancel()
        completer = nil
        isSearching = false
        isSuggesting = false
    }

    func searchPlaces(completion: MKLocalSearchCompletion? = nil) async {
        guard !Task.isCancelled, query.count >= 2 || completion != nil else { return }
        cancel()
        let id = generation
        suggestions = []
        results = []
        errorMessage = nil
        didSearch = true
        isSearching = true
        let request: MKLocalSearch.Request
        if let completion { request = MKLocalSearch.Request(completion: completion) }
        else {
            request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
        }
        request.region = region
        request.resultTypes = [.address, .pointOfInterest]
        let operation = MKLocalSearch(request: request)
        search = operation
        defer { if generation == id { isSearching = false; search = nil } }
        do {
            let response = try await operation.start()
            guard generation == id, !Task.isCancelled else { return }
            var places: [Destination] = []
            for item in response.mapItems {
                let point = item.placemark.coordinate
                let place = Destination(name: item.name ?? query, subtitle: item.placemark.title ?? "",
                                        latitude: point.latitude, longitude: point.longitude)
                if place.isValid && !places.contains(where: { $0.isSamePlace(as: place) }) { places.append(place) }
            }
            results = places
        } catch {
            guard generation == id, !Task.isCancelled else { return }
            if let mapError = error as? MKError, mapError.code == .placemarkNotFound {
                results = []
            } else {
                errorMessage = "Places could not load. Check your internet connection, then try again. You can also choose a pin on the map."
            }
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        guard self.completer === completer else { return }
        suggestions = Array(completer.results.prefix(10))
        isSuggesting = false
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        guard self.completer === completer else { return }
        isSuggesting = false
        errorMessage = "Suggestions are unavailable. Tap Search to try the full place search."
    }
}

struct DestinationSearchView: View {
    var onSelect: ((Destination) -> Void)? = nil
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var search = DestinationSearch()
    @State private var query = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var showMapPicker = false
    @State private var selectedDestination: Destination?
    @FocusState private var searchFocused: Bool

    private var cleanQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var savedDestinations: [Destination] {
        var seen = Set<UUID>()
        return appState.savedStops.map(\.destination).filter { seen.insert($0.id).inserted }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Button { searchFocused = false; showMapPicker = true } label: {
                        HStack {
                            Label("Choose a pin on the map", systemImage: "map")
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption.bold())
                        }.font(.subheadline.weight(.semibold)).padding(16)
                            .background(BabaNaTheme.softGreen).clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    if cleanQuery.count < 2 {
                        Text("Find your next stop").font(.title2.bold())
                        Text("Search a terminal, school, mall, or address. Add the city for a more specific result.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        if !appState.savedStops.isEmpty {
                            sectionTitle("Saved stops")
                            rows(savedDestinations, icon: "heart")
                        }
                        if !appState.recentDestinations.isEmpty {
                            sectionTitle("Recently visited")
                            rows(appState.recentDestinations, icon: "clock")
                        }
                    } else {
                        searchContent
                    }
                    Text(locationManager.currentLocation == nil ? "Search is centered on the Philippines. Location access is optional for searching." : "Suggestions prioritize places near your location.")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(20)
            }.scrollDismissesKeyboard(.interactively)
        }
        .background(BabaNaTheme.background)
        .navigationTitle("Find your stop")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: query) { _, _ in updateSuggestions() }
        .onAppear { updateSuggestions(); locationManager.requestCurrentLocation() }
        .onReceive(locationManager.$currentLocation) { fix in
            guard fix != nil, !search.didSearch else { return }
            updateSuggestions(near: fix?.coordinate)
        }
        .onDisappear { searchTask?.cancel(); search.cancel() }
        .navigationDestination(item: $selectedDestination) { SetTripView(destination: $0) }
        .sheet(isPresented: $showMapPicker) {
            NavigationStack {
                MapDestinationPicker { place in
                    showMapPicker = false
                    select(place)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(BabaNaTheme.green)
            TextField("Place, address, or city", text: $query)
                .focused($searchFocused).autocorrectionDisabled()
                .submitLabel(.search).onSubmit { submit() }
                .accessibilityLabel("Destination search")
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    .frame(minWidth: 44, minHeight: 44).accessibilityLabel("Clear search")
            }
            Button("Search") { submit() }
                .font(.subheadline.bold()).disabled(cleanQuery.count < 2 || search.isSearching)
        }
        .padding(.horizontal, 14).frame(minHeight: 56)
        .background(BabaNaTheme.card).clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(BabaNaTheme.divider, lineWidth: 1))
        .padding(.horizontal, 20).padding(.vertical, 12)
    }

    @ViewBuilder private var searchContent: some View {
        if search.isSearching {
            ProgressView("Finding places…").frame(maxWidth: .infinity).padding(32)
        } else {
            if let error = search.errorMessage {
                InfoBanner(text: error, icon: "wifi.exclamationmark")
                Button("Try search again") { submit() }.buttonStyle(.bordered)
            }
            if !search.results.isEmpty {
                sectionTitle("Choose your destination")
                rows(search.results, icon: "mappin.and.ellipse")
            } else if search.didSearch && search.errorMessage == nil {
                ContentUnavailableView("No matching places", systemImage: "mappin.slash",
                    description: Text("Try a landmark and city, or choose the exact stop on the map."))
            } else if !search.suggestions.isEmpty {
                sectionTitle("Suggestions")
                VStack(spacing: 0) {
                    ForEach(Array(search.suggestions.enumerated()), id: \.offset) { _, suggestion in
                        Button { submit(completion: suggestion) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass").foregroundStyle(BabaNaTheme.green)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(suggestion.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                    Text(suggestion.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.up.left").font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 14).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }.babaCard()
            } else if search.isSuggesting {
                ProgressView("Finding suggestions…").frame(maxWidth: .infinity).padding()
                Text("You can also tap Search above.").font(.caption).foregroundStyle(.secondary)
            } else if !search.didSearch {
                Text("Tap Search to find places matching “\(cleanQuery)”.").foregroundStyle(.secondary)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View { Text(title).font(.headline) }
    private func rows(_ destinations: [Destination], icon: String) -> some View {
        VStack(spacing: 0) {
            ForEach(destinations) { destination in
                Button { select(destination) } label: {
                    HStack {
                        DestinationRow(destination: destination, icon: icon)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }.babaCard()
    }

    private func updateSuggestions(near coordinate: CLLocationCoordinate2D? = nil) {
        searchTask?.cancel()
        search.update(query: query, near: coordinate ?? locationManager.currentLocation?.coordinate)
    }
    private func submit(completion: MKLocalSearchCompletion? = nil) {
        searchFocused = false
        searchTask?.cancel()
        searchTask = Task { await search.searchPlaces(completion: completion) }
    }
    private func select(_ destination: Destination) {
        searchFocused = false
        if let onSelect { onSelect(destination) } else { selectedDestination = destination }
    }
}
