import Foundation

enum TripAlert: String { case approaching, arrival }

enum TripRules {
    static let arrivalMeters: Double = 150
    /// A fix taken a few seconds before tapping Start is still current, so the
    /// trip can use it right away instead of waiting for a brand-new GPS reading.
    static let startGraceSeconds: TimeInterval = 10

    static func isFix(at timestamp: Date, usableFor trip: ActiveTrip) -> Bool {
        timestamp >= trip.startedAt.addingTimeInterval(-startGraceSeconds)
    }

    static func isValidReminder(_ meters: Double) -> Bool {
        meters.isFinite && (200...5000).contains(meters)
    }

    static func acceptsLocation(accuracy: Double, timestamp: Date, now: Date) -> Bool {
        let age = now.timeIntervalSince(timestamp)
        return accuracy.isFinite && (0...100).contains(accuracy) && (-5...30).contains(age)
    }

    static func alert(distance: Double, accuracy: Double, timestamp: Date,
                      now: Date, trip: ActiveTrip) -> TripAlert? {
        guard distance.isFinite, distance >= 0, isValidReminder(trip.reminderMeters),
              acceptsLocation(accuracy: accuracy, timestamp: timestamp, now: now),
              isFix(at: timestamp, usableFor: trip) else { return nil }
        // Arrival takes priority: a first fix inside 150 m must not send two alerts.
        if distance <= arrivalMeters { return .arrival }
        if distance <= trip.reminderMeters && !trip.didSendApproachingAlert { return .approaching }
        return nil
    }

    static func distanceText(_ meters: Double) -> String {
        guard meters.isFinite, meters >= 0 else { return "Locating..." }
        return meters < 1000 ? "\(Int(meters)) m" : String(format: "%.1f km", meters / 1000)
    }
}
