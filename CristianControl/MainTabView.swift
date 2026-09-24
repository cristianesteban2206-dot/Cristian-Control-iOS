import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Inicio", systemImage: "heart.fill") }

            NavigationStack { FinanceView() }
                .tabItem { Label("Finanzas", systemImage: "creditcard.fill") }

            NavigationStack { HealthHubView() }
                .tabItem { Label("Bienestar", systemImage: "figure.run.circle.fill") }

            NavigationStack { StatisticsView() }
                .tabItem { Label("Estadísticas", systemImage: "chart.xyaxis.line") }

            NavigationStack { MoreView() }
                .tabItem { Label("Más", systemImage: "square.grid.2x2.fill") }
        }
        .tint(CCTheme.pink)
    }
}
