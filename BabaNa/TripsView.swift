import SwiftUI

struct TripsView: View {
    @EnvironmentObject var appState: AppState
    @State private var filter: TripFilter = .all

    enum TripFilter: String, CaseIterable {
        case all = "All"
        case completed = "Completed"
        case cancelled = "Cancelled"
        case interrupted = "Interrupted"
    }

    private var filteredTrips: [TripRecord] {
        switch filter {
        case .all:
            return appState.trips
        case .completed:
            return appState.trips.filter { $0.status == .completed }
        case .cancelled:
            return appState.trips.filter { $0.status == .cancelled }
        case .interrupted:
            return appState.trips.filter { $0.status == .interrupted }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TripFilter.allCases, id: \.self) { item in
                        Button { filter = item } label: {
                            Text(item.rawValue).font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16).frame(minHeight: 44)
                                .foregroundStyle(filter == item ? Color.white : BabaNaTheme.green)
                                .background(filter == item ? BabaNaTheme.forest : BabaNaTheme.softGreen, in: Capsule())
                        }.buttonStyle(.plain)
                            .accessibilityAddTraits(filter == item ? [.isSelected] : [])
                    }
                }.padding(.horizontal, 20)
            }

            if filteredTrips.isEmpty {
                Spacer()

                ContentUnavailableView(
                    filter == .all ? "No trips yet" : "No \(filter.rawValue.lowercased()) trips",
                    systemImage: "bus",
                    description: Text(filter == .all ? "Start a trip and your ride history will appear here." : "Choose another filter to view your rides.")
                )

                Spacer()
            } else {
                List(filteredTrips) { trip in
                    HStack(spacing: 13) {
                        Image(systemName: trip.status == .completed ? "checkmark" : (trip.status == .interrupted ? "exclamationmark" : "xmark"))
                            .font(.caption.bold())
                            .foregroundStyle(trip.status == .completed ? BabaNaTheme.green : (trip.status == .interrupted ? .orange : .secondary))
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
                            .foregroundStyle(trip.status == .completed ? BabaNaTheme.green : (trip.status == .interrupted ? .orange : .secondary))
                    }
                    .padding(.vertical, 5)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(BabaNaTheme.background)
        .navigationTitle("Ride history")
    }

    private func reminderText(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }
}
