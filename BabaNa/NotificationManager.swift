import Foundation
import UserNotifications
import UIKit
import Combine

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var errorMessage: String?
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        refreshAuthorization()
    }

    func refreshAuthorization() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized ||
                    settings.authorizationStatus == .provisional || settings.authorizationStatus == .ephemeral
            }
        }
    }

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.errorMessage = error?.localizedDescription
                self?.refreshAuthorization()
            }
        }
    }

    func send(alert: TripAlert, trip: ActiveTrip, completion: @escaping (Bool) -> Void) {
        let content = UNMutableNotificationContent()
        content.title = alert == .arrival ? "Baba Na!" : "Malapit ka na!"
        content.body = alert == .arrival
            ? "You are within 150 m of \(trip.destination.name). Check your stop and prepare to get off."
            : "You are within \(TripRules.distanceText(trip.reminderMeters)) of \(trip.destination.name)."
        content.threadIdentifier = "BabaNaTrips"
        if UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true { content.sound = .default }
        let request = UNNotificationRequest(identifier: "trip-\(trip.id.uuidString)-\(alert.rawValue)",
                                             content: content, trigger: nil)
        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional ||
                    settings.authorizationStatus == .ephemeral else {
                DispatchQueue.main.async {
                    self?.isAuthorized = false
                    self?.errorMessage = "Notifications are off. Enable them in iPhone Settings."
                    completion(false)
                }
                return
            }
            self?.center.add(request) { error in
                DispatchQueue.main.async {
                    self?.errorMessage = error?.localizedDescription
                    completion(error == nil)
                }
            }
        }
    }

    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "BabaNa test reminder"
        content.body = "Trip notifications are working. This is only a test."
        if UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true { content.sound = .default }
        center.add(UNNotificationRequest(identifier: "babana-test",
                                         content: content,
                                         trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))) { [weak self] error in
            DispatchQueue.main.async { self?.errorMessage = error?.localizedDescription }
        }
    }

    func clearTrip(_ id: UUID) {
        let ids = ["trip-\(id.uuidString)-approaching", "trip-\(id.uuidString)-arrival"]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    func clearAllTripNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        DispatchQueue.main.async {
            if UserDefaults.standard.object(forKey: "vibrationEnabled") as? Bool ?? true {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
            completionHandler(notification.request.content.sound == nil ? [.banner, .list] : [.banner, .list, .sound])
        }
    }
}
