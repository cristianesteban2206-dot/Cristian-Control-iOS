import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \FinanceEntry.date) private var finances: [FinanceEntry]
    @Query(sort: \WeightEntry.date) private var weights: [WeightEntry]
    @Query(sort: \ActivityEntry.date) private var activities: [ActivityEntry]

    @State private var segment = 0

    private var expenseByCategory: [(String, Double)] {
        let ex = finances.filter { $0.type == .expense }
        return Dictionary(grouping: ex, by: \.category)
            .map { ($0.key, $0.value.reduce(0){$0+$1.amount}) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        ZStack {
            CCTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Estadística", selection: $segment) {
                        Text("Finanzas").tag(0)
                        Text("Peso").tag(1)
                        Text("Actividad").tag(2)
                    }
                    .pickerStyle(.segmented)

                    if segment == 0 {
                        PremiumCard {
                            VStack(alignment: .leading) {
                                Text("Gastos por categoría").font(.headline)
                                if expenseByCategory.isEmpty {
                                    Text("Todavía no hay datos").foregroundStyle(.secondary).padding(.vertical, 40)
                                } else {
                                    Chart(expenseByCategory, id: \.0) { item in
                                        BarMark(x: .value("Monto", item.1), y: .value("Categoría", item.0))
                                            .foregroundStyle(CCTheme.gradient)
                                    }
                                    .frame(height: max(240, CGFloat(expenseByCategory.count) * 36))
                                }
                            }
                        }
                    } else if segment == 1 {
                        PremiumCard {
                            VStack(alignment: .leading) {
                                Text("Evolución del peso").font(.headline)
                                if weights.isEmpty {
                                    Text("Todavía no hay pesajes").foregroundStyle(.secondary).padding(.vertical, 40)
                                } else {
                                    Chart(weights) { item in
                                        LineMark(x: .value("Fecha", item.date), y: .value("Peso", item.weight))
                                            .foregroundStyle(CCTheme.gradient)
                                    }
                                    .frame(height: 260)
                                    HStack {
                                        MetricPill(title: "Mínimo", value: (weights.map(\.weight).min() ?? 0).kg, symbol: "arrow.down")
                                        MetricPill(title: "Máximo", value: (weights.map(\.weight).max() ?? 0).kg, symbol: "arrow.up")
                                    }
                                }
                            }
                        }
                    } else {
                        let monthly = monthlyActivityCounts()
                        PremiumCard {
                            VStack(alignment: .leading) {
                                Text("Días activos por mes").font(.headline)
                                if monthly.isEmpty {
                                    Text("Todavía no hay actividades").foregroundStyle(.secondary).padding(.vertical, 40)
                                } else {
                                    Chart(monthly, id: \.0) { item in
                                        BarMark(x: .value("Mes", item.0), y: .value("Actividades", item.1))
                                            .foregroundStyle(CCTheme.gradient)
                                    }
                                    .frame(height: 260)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Estadísticas")
    }

    private func monthlyActivityCounts() -> [(String, Int)] {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_AR")
        fmt.dateFormat = "MMM"
        let grouped = Dictionary(grouping: activities) { entry in
            let comps = Calendar.current.dateComponents([.year,.month], from: entry.date)
            return "\(comps.year ?? 0)-\(comps.month ?? 0)"
        }
        return grouped.keys.sorted().suffix(12).map { key in
            let parts = key.split(separator: "-").compactMap { Int($0) }
            var comps = DateComponents()
            if parts.count == 2 { comps.year = parts[0]; comps.month = parts[1] }
            let d = Calendar.current.date(from: comps) ?? .now
            return (fmt.string(from: d).capitalized, grouped[key]?.count ?? 0)
        }
    }
}
