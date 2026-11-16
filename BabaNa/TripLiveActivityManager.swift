import Foundation
import ActivityKit

/// Shows the active trip on the Lock Screen and Dynamic Island.
/// Updates are local (no push server): they arrive while BabaNa keeps receiving
/// background location during a trip. If the app is swiped away, the activity
/// goes stale instead of showing an old distance as if it were current.
final class TripLiveActivityManager {
    private var activity: Activity<TripActivityAttributes>?
    private var state = TripActivityAttributes.ContentState(phase: .locating)
    private var lastSentDistance: Double?
    private var lastSentAt = Date.distantPast

    /// Sent distance changes smaller than this are skipped to save battery and avoid throttling.
    private let minDistanceChange: Double = 40
    private let minInterval: TimeInterval = 15
    /// Lock Screen marks the activity stale if no update arrives within this time.
    private let staleAfter: TimeInterval = 180

    init() {
        // A trip never survives a relaunch (AppState records it as interrupted),
        // so remove any Live Activity left over from a previous run.
        let leftovers = Activity<TripActivityAttributes>.activities
        Task {
            for old in leftovers { await old.end(nil, dismissalPolicy: .immediate) }
        }
    }

    func start(trip: ActiveTrip) {
        endImmediately()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = TripActivityAttributes(destinationName: trip.destination.name,
                                                reminderMeters: trip.reminderMeters,
                                                startedAt: trip.startedAt)
        state = .init(phase: .locating)
        lastSentDistance = nil
        lastSentAt = .distantPast
        do {
            activity = try Activity.request(attributes: attributes,
                                            content: content(),
                                            pushType: nil)
        } catch {
            // Live Activity is optional; the trip and its alarm still work without it.
            activity = nil
        }
    }

    /// Call with every accepted GPS distance during the trip.
    func update(distance: Double, reminderMeters: Double, approachingSent: Bool) {
        guard activity != nil, distance.isFinite, distance >= 0 else { return }
        if state.startMeters == nil { state.startMeters = max(distance, 1) }
        let phase: TripActivityPhase = (approachingSent || distance <= reminderMeters) ? .approaching : .onTheWay
        let phaseChanged = phase != state.phase
        state.phase = phase
        state.distanceMeters = distance

        let moved = lastSentDistance.map { abs($0 - distance) >= minDistanceChange } ?? true
        let waited = Date().timeIntervalSince(lastSentAt) >= minInterval
        guard phaseChanged || (moved && waited) else { return }
        send()
    }

    func markApproaching() {
        guard activity != nil, state.phase != .approaching else { return }
        state.phase = .approaching
        send()
    }

    /// Arrival: show a final "Baba na" state for a few minutes, then let iOS remove it.
    func finishArrived() {
        guard let current = activity else { return }
        activity = nil
        state.phase = .arrived
        state.distanceMeters = 0
        let final = ActivityContent(state: state, staleDate: nil)
        Task { await current.end(final, dismissalPolicy: .after(Date().addingTimeInterval(5 * 60))) }
    }

    /// Cancelled, interrupted, or signed out: remove it right away.
    func endImmediately() {
        guard let current = activity else { return }
        activity = nil
        Task { await current.end(nil, dismissalPolicy: .immediate) }
    }

    private func send() {
        guard let current = activity else { return }
        lastSentDistance = state.distanceMeters
        lastSentAt = Date()
        let next = content()
        Task { await current.update(next) }
    }

    private func content() -> ActivityContent<TripActivityAttributes.ContentState> {
        ActivityContent(state: state, staleDate: Date().addingTimeInterval(staleAfter))
    }
}
