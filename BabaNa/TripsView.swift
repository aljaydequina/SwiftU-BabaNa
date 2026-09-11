import SwiftUI

struct TripsView: View {
    @EnvironmentObject var appState: AppState
    @State private var filter: TripFilter = .all

    enum TripFilter: String, CaseIterable {
        case all = "All"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }

    private var filteredTrips: [TripRecord] {
        switch filter {
        case .all:
            return appState.trips
        case .completed:
            return appState.trips.filter { $0.status == .completed }
        case .cancelled:
            return appState.trips.filter { $0.status == .cancelled }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("Filter", selection: $filter) {
                ForEach(TripFilter.allCases, id: \.self) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 4)

            if filteredTrips.isEmpty {
                Spacer()

                ContentUnavailableView(
                    "No trips yet",
                    systemImage: "bus",
                    description: Text("Your trip history will appear here.")
                )

                Spacer()
            } else {
                List(filteredTrips) { trip in
                    HStack(spacing: 13) {
                        Image(systemName: trip.status == .completed ? "checkmark" : "xmark")
                            .font(.caption.bold())
                            .foregroundStyle(trip.status == .completed ? BabaNaTheme.green : .red)
                            .frame(width: 34, height: 34)
                            .background(
                                trip.status == .completed
                                ? BabaNaTheme.softGreen
                                : Color.red.opacity(0.10)
                            )
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.destination)
                                .font(.subheadline.weight(.semibold))

                            Text(trip.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("Reminder: \(reminderText(trip.reminderMeters))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(trip.status.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(trip.status == .completed ? BabaNaTheme.green : .red)
                    }
                    .padding(.vertical, 5)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(BabaNaTheme.background)
        .navigationTitle("Trips")
    }

    private func reminderText(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }
}
