import Foundation
import UserNotifications
import UIKit
import Combine
import AVFoundation

struct EmergencyTripAlert: Identifiable {
    let id: String
    let title: String
    let message: String
}

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var errorMessage: String?
    private let center = UNUserNotificationCenter.current()
    @Published var emergencyAlert: EmergencyTripAlert?
    private var alarmPlayer: AVAudioPlayer?
    private let alarmFilename = "BabaNaAlert.wav"

    private var soundEnabled: Bool { UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true }

    private func notificationSound() -> UNNotificationSound? {
        soundEnabled ? UNNotificationSound(named: UNNotificationSoundName(rawValue: alarmFilename)) : nil
    }

    private func displayEmergency(_ notification: UNNotification) {
        let content = notification.request.content
        emergencyAlert = EmergencyTripAlert(id: notification.request.identifier,
                                            title: content.title, message: content.body)
        if UserDefaults.standard.object(forKey: "vibrationEnabled") as? Bool ?? true {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        startAlarm()
    }

    private func startAlarm() {
        alarmPlayer?.stop()
        alarmPlayer = nil
        guard soundEnabled, let url = Bundle.main.url(forResource: "BabaNaAlert", withExtension: "wav") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // Foreground alert repeats until acknowledged.
            player.prepareToPlay()
            player.play()
            alarmPlayer = player
        } catch { errorMessage = "Could not play alert sound: \(error.localizedDescription)" }
    }

    func acknowledgeEmergency() {
        alarmPlayer?.stop()
        alarmPlayer = nil
        emergencyAlert = nil
    }

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
        if authorizationStatus == .denied { openSettings(); return }
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
        content.interruptionLevel = .timeSensitive
        content.sound = notificationSound()
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
        content.sound = notificationSound()
        content.interruptionLevel = .timeSensitive
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
        acknowledgeEmergency()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.displayEmergency(notification)
            // Playback is handled by the looping in-app alarm to avoid playing two sounds at once.
            completionHandler([.banner, .list])
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.displayEmergency(response.notification)
            completionHandler()
        }
    }
}
