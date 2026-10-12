import SwiftUI

struct SavedStopsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddStop = false
    var body: some View {
        List {
            if appState.savedStops.isEmpty {
                ContentUnavailableView("No saved stops", systemImage: "heart",
                                       description: Text("Keep your home, school, and everyday stops one tap away."))
                Button { showAddStop = true } label: { Label("Save your first stop", systemImage: "plus") }
                    .buttonStyle(BabaNaPrimaryButtonStyle()).listRowBackground(Color.clear)
            }
            ForEach(appState.savedStops) { stop in
                NavigationLink { SetTripView(destination: stop.destination) } label: {
                    HStack(spacing: 14) {
                        Image(systemName: stop.icon).foregroundStyle(BabaNaTheme.green)
                            .frame(width: 44, height: 44).background(BabaNaTheme.softGreen, in: RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stop.label).font(.headline)
                            Text(stop.destination.name).font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 8)
                }
            }.onDelete { appState.savedStops.remove(atOffsets: $0) }
        }
        .scrollContentBackground(.hidden)
        .background(BabaNaTheme.background)
        .navigationTitle("Saved stops")
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
