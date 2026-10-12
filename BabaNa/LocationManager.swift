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
    @Published private(set) var isLocating = false

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var permissionTitle: String {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return reducedAccuracy ? "Precise Location is off" : "Location ready"
        case .denied: return "Location access is off"
        case .restricted: return "Location access is restricted"
        default: return "Enable your location"
        }
    }

    var permissionDetail: String {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return reducedAccuracy ? "Turn on Precise Location in Settings for stop reminders." : "Find nearby places and get reminded before your stop."
        case .denied: return "Open Settings to allow location. If Location Services is off, enable it in Privacy & Security."
        case .restricted: return "Check Screen Time or device restrictions. You can still search and save places."
        default: return "Choose Allow While Using App. Location is monitored continuously only during a trip."
        }
    }

    var permissionAction: String {
        if authorizationStatus == .denied || authorizationStatus == .restricted || reducedAccuracy { return "Open Settings" }
        return isAuthorized ? "Refresh location" : "Allow Location"
    }

    var hasBackgroundConfiguration: Bool {
        (Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String])?.contains("location") == true
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

    func refreshAuthorization(requestLocation: Bool = true) {
        authorizationStatus = manager.authorizationStatus
        reducedAccuracy = manager.accuracyAuthorization == .reducedAccuracy
        if !isAuthorized {
            currentLocation = nil
            stopUpdatingLocation()
            locationError = authorizationStatus == .notDetermined ? nil : permissionDetail
        } else if requestLocation && !wantsTripUpdates {
            requestCurrentLocation()
        }
    }

    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            guard let purpose = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") as? String,
                  !purpose.isEmpty else {
                locationError = "Location permission is missing from this build. Rebuild using the included BabaNa.xcodeproj."
                return
            }
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            openSettings()
        case .authorizedAlways, .authorizedWhenInUse:
            if reducedAccuracy { openSettings() } else { requestCurrentLocation() }
        @unknown default:
            openSettings()
        }
    }

    func requestCurrentLocation() {
        guard isAuthorized, !wantsTripUpdates, !isLocating else { return }
        isLocating = true
        locationError = nil
        manager.requestLocation()
    }

    func startUpdatingLocation() {
        guard isAuthorized, hasBackgroundConfiguration else { return }
        wantsTripUpdates = true
        currentLocation = nil
        locationError = nil
        isLocating = true
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        wantsTripUpdates = false
        isLocating = false
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }

    func distance(to destination: Destination) -> Double? {
        guard let fix = currentLocation,
              TripRules.acceptsLocation(accuracy: fix.horizontalAccuracy, timestamp: fix.timestamp, now: Date()) else { return nil }
        return fix.distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refreshAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isAuthorized, let latest = locations.last, latest.horizontalAccuracy >= 0 else { return }
        isLocating = false
        currentLocation = latest
        locationError = TripRules.acceptsLocation(accuracy: latest.horizontalAccuracy, timestamp: latest.timestamp, now: Date())
            ? nil : "Waiting for accurate GPS. Enable Precise Location and try an open area."
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocating = false
        if let error = error as? CLError, error.code == .denied {
            refreshAuthorization(requestLocation: false)
            locationError = "Location is unavailable. Check Location Services and BabaNa permissions in Settings."
        } else {
            locationError = "Could not get your location. Try again with a clear GPS signal."
        }
    }
}
