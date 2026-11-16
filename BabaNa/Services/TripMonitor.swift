import Foundation
import Combine
import CoreLocation

// Owned by the app, not a screen: navigation never starts/stops monitoring.
final class TripMonitor: ObservableObject {
    private let appState: AppState
    private let location: LocationManager
    private let notifications: NotificationManager
    private var subscriptions = Set<AnyCancellable>()
    private var pendingAlert: String?
    private let liveActivity = TripLiveActivityManager()

    init(appState: AppState, location: LocationManager, notifications: NotificationManager) {
        self.appState = appState
        self.location = location
        self.notifications = notifications

        location.$currentLocation.compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fix in self?.process(fix) }
            .store(in: &subscriptions)
        appState.$activeTrip.map { $0?.id }.removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in
                guard let self, id == nil, !self.appState.isTripActive else { return }
                self.location.stopUpdatingLocation()
                self.pendingAlert = nil
            }
            .store(in: &subscriptions)
        // Any way a trip ends (cancel, interruption, sign-out) removes the Live Activity.
        // Arrival ends it earlier with a final "Baba na" state, so this is then a no-op.
        appState.$activeTrip.map { $0?.id }.removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in if id == nil { self?.liveActivity.endImmediately() } }
            .store(in: &subscriptions)
        location.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self, self.appState.isTripActive,
                      status == .denied || status == .restricted else { return }
                self.appState.endTrip(status: .interrupted)
                self.appState.notice = "Location access was removed. Enable it in Settings and start a new trip."
            }
            .store(in: &subscriptions)
    }

    func start(destination: Destination, reminderMeters: Double) -> String? {
        guard !appState.isTripActive else { return "End your current trip before starting another one." }
        guard location.isAuthorized else { return "Allow location access before starting your trip." }
        guard !location.reducedAccuracy else { return "Enable Precise Location in Settings before starting your trip." }
        guard location.hasBackgroundConfiguration else { return "Background location is missing from this build. Use the included BabaNa.xcodeproj." }
        guard notifications.isAuthorized else { return "Allow notifications before starting your trip." }
        guard appState.startTrip(destination: destination, reminderMeters: reminderMeters) else {
            return "This trip could not be started. Check your destination and reminder distance."
        }
        pendingAlert = nil
        if let trip = appState.activeTrip { liveActivity.start(trip: trip) }
        location.startUpdatingLocation()
        // Check right away with the recent fix instead of waiting for the next one.
        if let fix = location.currentLocation { process(fix) }
        return nil
    }

    private func process(_ fix: CLLocation) {
        guard let trip = appState.activeTrip else { return }
        let target = CLLocation(latitude: trip.destination.latitude, longitude: trip.destination.longitude)
        let distance = fix.distance(from: target)
        if TripRules.acceptsLocation(accuracy: fix.horizontalAccuracy, timestamp: fix.timestamp, now: Date()),
           TripRules.isFix(at: fix.timestamp, usableFor: trip) {
            liveActivity.update(distance: distance, reminderMeters: trip.reminderMeters,
                                approachingSent: trip.didSendApproachingAlert)
        }
        guard let alert = TripRules.alert(distance: distance,
                                          accuracy: fix.horizontalAccuracy, timestamp: fix.timestamp,
                                          now: Date(), trip: trip) else { return }
        guard pendingAlert == nil else { return }
        let key = "trip-\(trip.id.uuidString)-\(alert.rawValue)"
        pendingAlert = key
        notifications.send(alert: alert, trip: trip) { [weak self] success in
            guard let self else { return }
            if self.pendingAlert == key { self.pendingAlert = nil }
            guard self.appState.activeTrip?.id == trip.id else {
                // A cancellation/sign-out may race the asynchronous scheduling call.
                self.notifications.clearTrip(trip.id)
                return
            }
            // Retry on the next valid GPS fix if scheduling failed.
            guard success else { return }
            if alert == .arrival {
                self.liveActivity.finishArrived()
                self.appState.endTrip(status: .completed)
                self.location.stopUpdatingLocation()
            } else {
                self.appState.markApproachingSent(tripID: trip.id)
                self.liveActivity.markApproaching()
            }
        }
    }

    func cancel() {
        if let trip = appState.activeTrip { notifications.clearTrip(trip.id) }
        appState.endTrip(status: .cancelled)
        location.stopUpdatingLocation()
        pendingAlert = nil
    }

    func accountDidChange() {
        cancel()
        notifications.clearAllTripNotifications()
    }
}
