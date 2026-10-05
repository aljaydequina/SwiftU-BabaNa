import Foundation
#if canImport(CoreLocation)
import CoreLocation
#endif

struct Destination: Identifiable, Hashable, Codable {
    var id = UUID()
    let name: String
    let subtitle: String
    let latitude: Double
    let longitude: Double

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        latitude.isFinite && longitude.isFinite &&
        (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }

    func isSamePlace(as other: Destination) -> Bool {
        name == other.name && abs(latitude - other.latitude) < 0.00001 &&
        abs(longitude - other.longitude) < 0.00001
    }

    #if canImport(CoreLocation)
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    #endif
}

struct SavedStop: Identifiable, Hashable, Codable {
    var id = UUID()
    var label: String
    var icon: String
    var destination: Destination
}

enum TripStatus: String, Codable {
    case completed = "Completed"
    case cancelled = "Cancelled"
    case interrupted = "Interrupted"
}

struct TripRecord: Identifiable, Codable {
    var id = UUID()
    let destination: String
    let status: TripStatus
    let reminderMeters: Double
    let date: Date
}

struct ActiveTrip: Identifiable, Codable {
    var id = UUID()
    let destination: Destination
    let reminderMeters: Double
    var startedAt = Date()
    var didSendApproachingAlert = false
}

struct TripSnapshot: Codable {
    var hasFinishedOnboarding = false
    var savedStops: [SavedStop] = []
    var trips: [TripRecord] = []
    var recentDestinations: [Destination] = []
    var activeTrip: ActiveTrip?
}
