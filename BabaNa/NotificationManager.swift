import Foundation
import UserNotifications
import Combine
final class NotificationManager: ObservableObject {
    @Published var isAuthorized = false

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }

    func sendApproachingNotification(destination: String, distanceText: String) {
        let content = UNMutableNotificationContent()
        content.title = "Malapit ka na!"
        content.body = "You're about \(distanceText) away from \(destination)."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "approaching-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendArrivalNotification(destination: String) {
        let content = UNMutableNotificationContent()
        content.title = "Baba Na!"
        content.body = "You are very close to \(destination). Prepare to get off."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "arrival-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
