import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var locationError: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 20
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        guard manager.authorizationStatus == .authorizedWhenInUse ||
              manager.authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    func distance(to destination: Destination) -> Double? {
        guard let currentLocation else { return nil }

        let destinationLocation = CLLocation(
            latitude: destination.latitude,
            longitude: destination.longitude
        )

        return currentLocation.distance(from: destinationLocation)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }

        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }

        DispatchQueue.main.async {
            self.currentLocation = latest
            self.locationError = nil
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
        }
    }
}
