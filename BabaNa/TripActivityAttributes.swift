import Foundation
import ActivityKit

// Shared by the app and the BabaNaWidgets extension.
// In Xcode, tick BOTH targets under File Inspector > Target Membership.
// `nonisolated` keeps the Codable conformances usable outside the main actor
// (the app target uses MainActor as its default isolation).
nonisolated struct TripActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        var phase: TripActivityPhase
        /// Straight-line distance to the stop, nil while waiting for accurate GPS.
        var distanceMeters: Double?
        /// First accurate distance of the trip, used for the progress bar.
        var startMeters: Double?
    }

    var destinationName: String
    var reminderMeters: Double
    var startedAt: Date
}

nonisolated enum TripActivityPhase: String, Codable, Hashable {
    case locating, onTheWay, approaching, arrived
}

nonisolated extension TripActivityAttributes.ContentState {
    var progress: Double {
        if phase == .arrived { return 1 }
        guard let distanceMeters, let startMeters, startMeters > 0 else { return 0 }
        return min(1, max(0, 1 - distanceMeters / startMeters))
    }

    var distanceText: String {
        if phase == .arrived { return "Nandito na" }
        guard let distanceMeters, distanceMeters.isFinite, distanceMeters >= 0 else { return "—" }
        return TripActivityAttributes.format(distanceMeters)
    }
}

nonisolated extension TripActivityAttributes {
    static func format(_ meters: Double) -> String {
        meters < 1000 ? "\(Int(meters.rounded())) m" : String(format: "%.1f km", meters / 1000)
    }
}
