import SwiftUI
import SwiftData

@main
struct CristianControlApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [
            FinanceEntry.self,
            WeightEntry.self,
            ActivityEntry.self,
            HabitEntry.self,
            BodyMeasurement.self,
            GoalItem.self
        ])
    }
}
