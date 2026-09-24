import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \FinanceEntry.date, order: .reverse) private var finances: [FinanceEntry]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]
    @Query(sort: \ActivityEntry.date, order: .reverse) private var activities: [ActivityEntry]
    @Query(sort: \HabitEntry.date, order: .reverse) private var habits: [HabitEntry]

    @AppStorage("cc.name") private var name = "Cristian"
    @AppStorage("cc.monthlyBudget") private var monthlyBudget = 0.0
    @AppStorage("cc.targetWeight") private var targetWeight = 0.0
    @AppStorage("cc.weeklyGoal") private var weeklyGoal = 3

    private var monthEntries: [FinanceEntry] {
        guard let interval = Calendar.current.dateInterval(of: .month, for: .now) else { return [] }
        return finances.filter { interval.contains($0.date) }
    }

    private var monthExpenses: Double {
        monthEntries.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var monthIncome: Double {
        monthEntries.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var weeklyActivities: Int {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return activities.filter { interval.contains($0.date) }.count
    }

    var body: some View {
        ZStack {
            CCTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hola, \(name) 💗")
                                .font(.largeTitle.bold())
                            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        HeartLogo(size: 38)
                    }

                    PremiumCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Balance del mes")
                                .foregroundStyle(.secondary)
                            Text((monthIncome - monthExpenses).ars)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(CCTheme.ink)
                            HStack {
                                MetricPill(title: "Ingresos", value: monthIncome.ars, symbol: "arrow.down.circle.fill")
                                MetricPill(title: "Gastos", value: monthExpenses.ars, symbol: "arrow.up.circle.fill")
                            }
                            if monthlyBudget > 0 {
                                ProgressView(value: min(monthExpenses / monthlyBudget, 1))
                                    .tint(CCTheme.pink)
                                Text("\(Int(min(monthExpenses / monthlyBudget, 1) * 100))% del presupuesto mensual")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack {
                        MetricPill(
                            title: "Peso actual",
                            value: weights.first?.weight.kg ?? "Sin registro",
                            symbol: "scalemass.fill"
                        )
                        MetricPill(
                            title: "Actividad",
                            value: "\(weeklyActivities)/\(weeklyGoal) días",
                            symbol: "figure.run"
                        )
                    }

                    if let last = activities.first {
                        PremiumCard {
                            HStack(spacing: 14) {
                                Image(systemName: last.kind.symbol)
                                    .font(.title2)
                                    .foregroundStyle(CCTheme.gradient)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Última actividad").font(.caption).foregroundStyle(.secondary)
                                    Text("\(last.kind.rawValue) · \(last.minutes) min").font(.headline)
                                    Text(last.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }

                    if let habit = habits.first, Calendar.current.isDateInToday(habit.date) {
                        HStack {
                            MetricPill(title: "Agua", value: "\(habit.waterGlasses) vasos", symbol: "drop.fill")
                            MetricPill(title: "Sueño", value: "\(habit.sleepHours.formatted(.number.precision(.fractionLength(1)))) h", symbol: "moon.fill")
                        }
                    }

                    InsightCard()
                }
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

private struct InsightCard: View {
    @Query(sort: \ActivityEntry.date, order: .reverse) private var activities: [ActivityEntry]

    var body: some View {
        let days = activities.first.map {
            Calendar.current.dateComponents([.day], from: $0.date, to: .now).day ?? 0
        }

        PremiumCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: days.map { $0 >= 2 ? "bell.badge.fill" : "sparkles" } ?? "sparkles")
                    .font(.title2)
                    .foregroundStyle(CCTheme.gradient)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Para hoy").font(.headline)
                    if let days, days >= 2 {
                        Text("Pasaron \(days) días desde tu última actividad. Una caminata corta también suma.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Mantené tus registros al día para ver tendencias reales de bienestar y finanzas.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
