import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var wantsTripUpdates = false
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var locationError: String?
    @Published private(set) var reducedAccuracy = false

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        manager.activityType = .automotiveNavigation
        manager.pausesLocationUpdatesAutomatically = false
        refreshAuthorization()
    }

    func refreshAuthorization() {
        authorizationStatus = manager.authorizationStatus
        reducedAccuracy = manager.accuracyAuthorization == .reducedAccuracy
    }

    func requestPermission() { manager.requestWhenInUseAuthorization() }

    func requestCurrentLocation() {
        guard isAuthorized, !wantsTripUpdates else { return }
        manager.requestLocation()
    }

    func startUpdatingLocation() {
        guard isAuthorized else { return }
        wantsTripUpdates = true
        currentLocation = nil
        locationError = nil
        // UIBackgroundModes/location is declared in Configuration/Info.plist.
        // Start from the foreground after the user explicitly starts a trip.
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        wantsTripUpdates = false
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }

    func distance(to destination: Destination) -> Double? {
        guard let fix = currentLocation,
              TripRules.acceptsLocation(accuracy: fix.horizontalAccuracy, timestamp: fix.timestamp, now: Date())
        else { return nil }
        return fix.distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refreshAuthorization()
        if !isAuthorized {
            currentLocation = nil
            if authorizationStatus == .denied || authorizationStatus == .restricted {
                locationError = "Location access is off. Enable it in iPhone Settings."
                stopUpdatingLocation()
            }
        } else if wantsTripUpdates {
            manager.startUpdatingLocation()
        } else {
            requestCurrentLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        currentLocation = latest
        locationError = TripRules.acceptsLocation(accuracy: latest.horizontalAccuracy,
                                                  timestamp: latest.timestamp, now: Date())
            ? nil : "Waiting for a more accurate GPS position. Enable Precise Location and move to an open area."
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = "GPS update unavailable. \(error.localizedDescription)"
    }
}
