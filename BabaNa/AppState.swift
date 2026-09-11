import Foundation
import CoreLocation
import Combine

final class AppState: ObservableObject {
    @Published var hasFinishedOnboarding = false
    @Published var selectedDestination: Destination?
    @Published var selectedReminderDistance: Double = 1000
    @Published var isTripActive = false
    @Published var tripStartDate: Date?
    @Published var didSendApproachingAlert = false
    @Published var didSendArrivalAlert = false

    @Published var savedStops: [SavedStop] = [
        SavedStop(label: "Home", icon: "house.fill", destination: Destination.samples[0]),
        SavedStop(label: "School", icon: "graduationcap.fill", destination: Destination.samples[1])
    ]

    @Published var trips: [TripRecord] = [
        TripRecord(destination: "Lucena Grand Terminal",
                   status: .completed,
                   reminderMeters: 500,
                   date: Date().addingTimeInterval(-3600)),
        TripRecord(destination: "SM City Lucena",
                   status: .completed,
                   reminderMeters: 1000,
                   date: Date().addingTimeInterval(-86400))
    ]

    func startTrip() {
        guard selectedDestination != nil else { return }
        isTripActive = true
        tripStartDate = Date()
        didSendApproachingAlert = false
        didSendArrivalAlert = false
    }

    func endTrip(status: TripStatus) {
        if let destination = selectedDestination {
            trips.insert(
                TripRecord(
                    destination: destination.name,
                    status: status,
                    reminderMeters: selectedReminderDistance,
                    date: Date()
                ),
                at: 0
            )
        }

        isTripActive = false
        tripStartDate = nil
        didSendApproachingAlert = false
        didSendArrivalAlert = false
    }
}
