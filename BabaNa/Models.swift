import Foundation
import CoreLocation
import Combine
struct Destination: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static let samples: [Destination] = [
        Destination(
            name: "Lucena Grand Terminal",
            subtitle: "Lucena City",
            latitude: 13.9416,
            longitude: 121.6127
        ),
        Destination(
            name: "SM City Lucena",
            subtitle: "Lucena City",
            latitude: 13.9380,
            longitude: 121.6110
        ),
        Destination(
            name: "Cubao, Quezon City",
            subtitle: "Metro Manila",
            latitude: 14.6198,
            longitude: 121.0545
        ),
        Destination(
            name: "PITX, Parañaque",
            subtitle: "Metro Manila",
            latitude: 14.5100,
            longitude: 120.9914
        ),
        Destination(
            name: "Alabang, Muntinlupa",
            subtitle: "Metro Manila",
            latitude: 14.4178,
            longitude: 121.0478
        ),
        Destination(
            name: "Candelaria, Quezon",
            subtitle: "Quezon Province",
            latitude: 13.9315,
            longitude: 121.4236
        )
    ]
}

struct SavedStop: Identifiable, Hashable {
    let id = UUID()
    var label: String
    var icon: String
    var destination: Destination
}

enum TripStatus: String {
    case completed = "Completed"
    case cancelled = "Cancelled"
}

struct TripRecord: Identifiable {
    let id = UUID()
    let destination: String
    let status: TripStatus
    let reminderMeters: Double
    let date: Date
}
