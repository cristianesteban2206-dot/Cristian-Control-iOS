import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var authorized = false

    private init() {}

    func requestPermission() async {
        do {
            authorized = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            authorized = false
        }
    }

    func scheduleInactivityReminder(from activityDate: Date = .now, days: Int = 2) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["activity.inactivity"])

        let content = UNMutableNotificationContent()
        content.title = "Cristian Control 💗"
        content.body = "Pasaron más de \(days) días sin actividad registrada. Un poco de movimiento también cuenta."
        content.sound = .default

        let target = Calendar.current.date(byAdding: .day, value: days, to: activityDate) ?? Date().addingTimeInterval(172800)
        let interval = max(60, target.timeIntervalSinceNow + 3600)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: "activity.inactivity", content: content, trigger: trigger))
    }

    func scheduleDailyWeightReminder(hour: Int = 9) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["weight.daily"])

        let content = UNMutableNotificationContent()
        content.title = "Registro de peso"
        content.body = "Si hoy te corresponde control, podés registrar tu peso en Cristian Control."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: "weight.daily", content: content, trigger: trigger))
    }

    func notifyBudget(level: String, spent: Double, budget: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Presupuesto mensual"
        content.body = "\(level) — llevás \(spent.ars) de \(budget.ars)."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "budget.\(UUID().uuidString)", content: content, trigger: trigger)
        )
    }
}
