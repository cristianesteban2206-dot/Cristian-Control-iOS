import SwiftUI
import SwiftData
import Charts

struct HealthHubView: View {
    @State private var segment = 0
    var body: some View {
        ZStack {
            CCTheme.background.ignoresSafeArea()
            VStack(spacing: 12) {
                Picker("Bienestar", selection: $segment) {
                    Text("Peso").tag(0)
                    Text("Actividad").tag(1)
                    Text("Hábitos").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if segment == 0 {
                    WeightView()
                } else if segment == 1 {
                    ActivityView()
                } else {
                    HabitsView()
                }
            }
        }
        .navigationTitle("Bienestar")
    }
}

struct WeightView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]
    @AppStorage("cc.targetWeight") private var targetWeight = 0.0
    @State private var showAdd = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PremiumCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Peso actual").foregroundStyle(.secondary)
                        Text(weights.first?.weight.kg ?? "Sin registro")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        if let first = weights.first, targetWeight > 0 {
                            Text("Meta: \(targetWeight.kg) · Diferencia: \(abs(first.weight-targetWeight).kg)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                if !weights.isEmpty {
                    PremiumCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Evolución").font(.headline)
                            Chart(weights.prefix(30).reversed()) { item in
                                LineMark(x: .value("Fecha", item.date), y: .value("Peso", item.weight))
                                    .foregroundStyle(CCTheme.gradient)
                                PointMark(x: .value("Fecha", item.date), y: .value("Peso", item.weight))
                                    .foregroundStyle(CCTheme.pink)
                            }
                            .frame(height: 220)
                        }
                    }
                }

                Button("Registrar peso") { showAdd = true }
                    .buttonStyle(PremiumButtonStyle())

                VStack(alignment: .leading, spacing: 10) {
                    Text("Historial").font(.headline)
                    ForEach(weights.prefix(12)) { item in
                        HStack {
                            Text(item.date.formatted(date: .abbreviated, time: .shortened))
                            Spacer()
                            Text(item.weight.kg).bold()
                        }
                        Divider()
                    }
                }
                .padding()
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 22))
            }
            .padding()
        }
        .sheet(isPresented: $showAdd) { NavigationStack { AddWeightView() } }
    }
}

struct AddWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var weight = ""
    @State private var note = ""
    @State private var date = Date()

    var body: some View {
        Form {
            Section("Pesaje") {
                TextField("Peso en kg", text: $weight).keyboardType(.decimalPad)
                DatePicker("Fecha y hora", selection: $date)
                TextField("Nota opcional", text: $note)
            }
            Button("Guardar pesaje") {
                let clean = weight.replacingOccurrences(of: ",", with: ".")
                if let value = Double(clean), value > 0 {
                    modelContext.insert(WeightEntry(weight: value, date: date, note: note))
                    dismiss()
                }
            }
        }
        .navigationTitle("Registrar peso")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
    }
}

struct ActivityView: View {
    @Query(sort: \ActivityEntry.date, order: .reverse) private var activities: [ActivityEntry]
    @AppStorage("cc.weeklyGoal") private var weeklyGoal = 3
    @State private var showAdd = false

    private var weekly: [ActivityEntry] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: .now) else { return [] }
        return activities.filter { interval.contains($0.date) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PremiumCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Actividad semanal").font(.headline)
                        Text("\(weekly.count) de \(weeklyGoal) días")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        ProgressView(value: min(Double(weekly.count)/Double(max(weeklyGoal,1)), 1))
                            .tint(CCTheme.pink)
                        Text("\(weekly.reduce(0){$0+$1.minutes}) minutos acumulados")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                Button("Registrar actividad") { showAdd = true }
                    .buttonStyle(PremiumButtonStyle())

                VStack(alignment: .leading, spacing: 12) {
                    Text("Actividad reciente").font(.headline)
                    ForEach(activities.prefix(12)) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.kind.symbol)
                                .foregroundStyle(CCTheme.gradient)
                                .font(.title3)
                            VStack(alignment: .leading) {
                                Text(item.kind.rawValue).bold()
                                Text("\(item.minutes) min · \(item.intensity)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(item.date.formatted(date: .numeric, time: .omitted))
                                .font(.caption)
                        }
                        Divider()
                    }
                }
                .padding()
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 22))
            }
            .padding()
        }
        .sheet(isPresented: $showAdd) { NavigationStack { AddActivityView() } }
    }
}

struct AddActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var kind: ActivityKind = .gym
    @State private var minutes = 45
    @State private var intensity = "Moderada"
    @State private var note = ""
    @State private var date = Date()

    var body: some View {
        Form {
            Section("Actividad") {
                Picker("Tipo", selection: $kind) {
                    ForEach(ActivityKind.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
                }
                Stepper("Duración: \(minutes) min", value: $minutes, in: 5...300, step: 5)
                Picker("Intensidad", selection: $intensity) {
                    ForEach(["Suave","Moderada","Alta"], id: \.self) { Text($0) }
                }
                DatePicker("Fecha", selection: $date)
                TextField("Notas", text: $note)
            }
            Button("Guardar actividad") {
                modelContext.insert(ActivityEntry(kind: kind, date: date, minutes: minutes, intensity: intensity, note: note))
                NotificationManager.shared.scheduleInactivityReminder(from: date)
                dismiss()
            }
        }
        .navigationTitle("Registrar actividad")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
    }
}

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HabitEntry.date, order: .reverse) private var habits: [HabitEntry]
    @State private var water = 0
    @State private var sleep = 7.0
    @State private var mood: Mood = .normal

    private var todayHabit: HabitEntry? {
        habits.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PremiumCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Hábitos de hoy").font(.title2.bold())
                        Stepper("Agua: \(water) vasos", value: $water, in: 0...20)
                        Stepper("Sueño: \(sleep.formatted(.number.precision(.fractionLength(1)))) h", value: $sleep, in: 0...14, step: 0.5)
                        Picker("Estado de ánimo", selection: $mood) {
                            ForEach(Mood.allCases) { Text("\($0.emoji) \($0.rawValue)").tag($0) }
                        }
                        Button("Guardar hábitos") { save() }
                            .buttonStyle(PremiumButtonStyle())
                    }
                }

                if !habits.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Últimos registros").font(.headline)
                        ForEach(habits.prefix(10)) { item in
                            HStack {
                                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                Spacer()
                                Text("💧\(item.waterGlasses)  🌙\(item.sleepHours.formatted(.number.precision(.fractionLength(1))))h  \(item.mood.emoji)")
                            }
                            Divider()
                        }
                    }
                    .padding()
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 22))
                }
            }
            .padding()
        }
        .onAppear {
            if let item = todayHabit {
                water = item.waterGlasses
                sleep = item.sleepHours
                mood = item.mood
            }
        }
    }

    private func save() {
        if let item = todayHabit {
            item.waterGlasses = water
            item.sleepHours = sleep
            item.mood = mood
        } else {
            modelContext.insert(HabitEntry(waterGlasses: water, sleepHours: sleep, mood: mood))
        }
    }
}
