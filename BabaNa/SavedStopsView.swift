import SwiftUI

struct SavedStopsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddStop = false
    var body: some View {
        List {
            if appState.savedStops.isEmpty {
                ContentUnavailableView("No saved stops", systemImage: "heart",
                                       description: Text("Tap + to save your home, school, or usual stop."))
            }
            ForEach(appState.savedStops) { stop in
                NavigationLink { SetTripView(destination: stop.destination) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(stop.label, systemImage: stop.icon).font(.headline)
                        Text(stop.destination.name).font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 6)
                }
            }.onDelete { appState.savedStops.remove(atOffsets: $0) }
        }
        .navigationTitle("Saved Stops")
        .toolbar { Button { showAddStop = true } label: { Image(systemName: "plus") }.accessibilityLabel("Add saved stop") }
        .sheet(isPresented: $showAddStop) { AddSavedStopView() }
    }
}

struct AddSavedStopView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var destination: Destination?
    @State private var icon = "star.fill"
    @State private var showSearch = false
    private let icons = ["house.fill", "graduationcap.fill", "briefcase.fill", "star.fill"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") { TextField("Home, school, or another label", text: $label) }
                Section("Destination") {
                    Button { showSearch = true } label: {
                        Text(destination?.name ?? "Search for a place")
                    }
                    if let destination { Text(destination.subtitle).font(.caption) }
                }
                Section("Icon") {
                    Picker("Icon", selection: $icon) {
                        ForEach(icons, id: \.self) { Image(systemName: $0).tag($0) }
                    }.pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Saved Stop").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let destination else { return }
                        appState.saveStop(label: label, icon: icon, destination: destination)
                        dismiss()
                    }.disabled(destination == nil)
                }
            }
            .sheet(isPresented: $showSearch) {
                NavigationStack {
                    DestinationSearchView { selected in destination = selected; showSearch = false }
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showSearch = false } } }
                }
            }
        }
    }
}
