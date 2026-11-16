import Foundation
import UserNotifications
import UIKit
import Combine
import AVFoundation
import AudioToolbox

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
    private var ringTask: Task<Void, Never>?
    private let alarmFilename = "BabaNaAlert.wav"
    private static let tripCategory = "BABANA_TRIP"
    private static let stopAction = "BABANA_STOP_ALARM"
    /// The alarm stops by itself after this long if nobody taps Stop.
    private let maxRingSeconds: TimeInterval = 180

    private var soundEnabled: Bool { UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true }
    private var vibrationEnabled: Bool { UserDefaults.standard.object(forKey: "vibrationEnabled") as? Bool ?? true }

    private func notificationSound() -> UNNotificationSound? {
        soundEnabled ? UNNotificationSound(named: UNNotificationSoundName(rawValue: alarmFilename)) : nil
    }

    private func displayEmergency(_ notification: UNNotification) {
        let content = notification.request.content
        presentAlarm(id: notification.request.identifier, title: content.title, message: content.body)
    }

    /// Shows the reminder card and rings until the rider stops it.
    /// During a trip the app keeps running in the background (location), so this
    /// also rings on the Lock Screen, not only while BabaNa is on screen.
    private func presentAlarm(id: String, title: String, message: String) {
        // The same reminder can arrive twice (right after scheduling and via willPresent).
        if emergencyAlert?.id == id, ringTask != nil { return }
        emergencyAlert = EmergencyTripAlert(id: id, title: title, message: message)
        if vibrationEnabled { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        startAlarm()
    }

    private func startAlarm() {
        stopAlarmSound()
        let vibrate = vibrationEnabled
        let limit = maxRingSeconds
        // Repeating vibration, and an automatic stop so it never rings forever.
        ringTask = Task { [weak self] in
            let started = Date()
            while !Task.isCancelled, Date().timeIntervalSince(started) < limit {
                if vibrate { AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) }
                try? await Task.sleep(for: .seconds(2.5))
            }
            if !Task.isCancelled { self?.stopAlarmSound() }
        }
        guard soundEnabled, let url = Bundle.main.url(forResource: "BabaNaAlert", withExtension: "wav") else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback rings even with the Silent switch on, like a clock alarm.
            // .duckOthers lowers music or videos while the alarm rings.
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // Repeats until acknowledged or the time limit.
            player.volume = 1
            player.prepareToPlay()
            player.play()
            alarmPlayer = player
        } catch { errorMessage = "Could not play alert sound: \(error.localizedDescription)" }
    }

    private func stopAlarmSound() {
        ringTask?.cancel()
        ringTask = nil
        guard let player = alarmPlayer else { return }
        player.stop()
        alarmPlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func acknowledgeEmergency() {
        if let id = emergencyAlert?.id { center.removeDeliveredNotifications(withIdentifiers: [id]) }
        stopAlarmSound()
        emergencyAlert = nil
    }

    override init() {
        super.init()
        center.delegate = self
        // Lets the rider stop the alarm from the Lock Screen without opening the app.
        let stop = UNNotificationAction(identifier: Self.stopAction, title: "Stop alarm", options: [])
        center.setNotificationCategories([
            UNNotificationCategory(identifier: Self.tripCategory, actions: [stop],
                                   intentIdentifiers: [], options: [.customDismissAction])
        ])
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
        content.categoryIdentifier = Self.tripCategory
        content.interruptionLevel = .timeSensitive
        content.sound = notificationSound()
        let request = UNNotificationRequest(identifier: "trip-\(trip.id.uuidString)-\(alert.rawValue)",
                                             content: content, trigger: nil)
        let alarmID = request.identifier
        let alarmTitle = content.title
        let alarmBody = content.body
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
                    // Ring from the app itself; the system notification sound alone
                    // plays once and is muted by the Silent switch and Focus.
                    if error == nil { self?.presentAlarm(id: alarmID, title: alarmTitle, message: alarmBody) }
                    completion(error == nil)
                }
            }
        }
    }

    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "BabaNa test reminder"
        content.body = "Trip notifications are working. This is only a test."
        content.categoryIdentifier = Self.tripCategory
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
            switch response.actionIdentifier {
            case NotificationManager.stopAction, UNNotificationDismissActionIdentifier:
                self?.acknowledgeEmergency()
            default:
                self?.displayEmergency(response.notification)
            }
            completionHandler()
        }
    }
}
