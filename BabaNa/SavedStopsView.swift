import SwiftUI

struct SavedStopsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddStop = false

    var body: some View {
        List {
            if appState.savedStops.isEmpty {
                ContentUnavailableView(
                    "No saved stops",
                    systemImage: "heart",
                    description: Text("Save places you use often for quicker trip setup.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(appState.savedStops) { stop in
                        NavigationLink {
                            SetTripView(destination: stop.destination)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: stop.icon)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BabaNaTheme.green)
                                    .frame(width: 38, height: 38)
                                    .background(BabaNaTheme.softGreen)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(stop.label)
                                        .font(.subheadline.weight(.semibold))

                                    Text(stop.destination.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                    .onDelete { offsets in
                        appState.savedStops.remove(atOffsets: offsets)
                    }
                } footer: {
                    Text("Swipe left on a saved stop to remove it.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(BabaNaTheme.background)
        .navigationTitle("Saved Stops")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddStop = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddStop) {
            AddSavedStopView()
        }
    }
}

struct AddSavedStopView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var selectedDestination = Destination.samples[0]
    @State private var selectedIcon = "star.fill"

    private let icons = [
        "house.fill",
        "graduationcap.fill",
        "briefcase.fill",
        "figure.run",
        "star.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Example: Home", text: $label)
                }

                Section("Destination") {
                    Picker("Choose stop", selection: $selectedDestination) {
                        ForEach(Destination.samples) { destination in
                            Text(destination.name).tag(destination)
                        }
                    }
                }

                Section("Icon") {
                    HStack(spacing: 10) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(
                                        selectedIcon == icon ? Color.white : BabaNaTheme.green
                                    )
                                    .frame(width: 42, height: 42)
                                    .background(
                                        selectedIcon == icon
                                        ? BabaNaTheme.green
                                        : BabaNaTheme.softGreen
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Saved Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newStop = SavedStop(
                            label: label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Saved Stop" : label,
                            icon: selectedIcon,
                            destination: selectedDestination
                        )

                        appState.savedStops.append(newStop)
                        dismiss()
                    }
                }
            }
        }
    }
}
