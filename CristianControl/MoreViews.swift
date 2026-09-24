import SwiftUI
import SwiftData
import LocalAuthentication
import UserNotifications

struct MoreView: View {
    var body: some View {
        ZStack {
            CCTheme.background.ignoresSafeArea()
            List {
                Section("Organización") {
                    NavigationLink { GoalsView() } label: { Label("Metas", systemImage: "target") }
                    NavigationLink { MeasurementsView() } label: { Label("Medidas corporales", systemImage: "ruler") }
                    NavigationLink { GlobalCalendarView() } label: { Label("Calendario integral", systemImage: "calendar") }
                    NavigationLink { AlertsView() } label: { Label("Centro de avisos", systemImage: "bell.badge.fill") }
                }
                Section("Aplicación") {
                    NavigationLink { SettingsView() } label: { Label("Ajustes", systemImage: "gearshape.fill") }
                    NavigationLink { AboutView() } label: { Label("Acerca de Cristian Control", systemImage: "heart.fill") }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Más")
    }
}

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GoalItem.title) private var goals: [GoalItem]
    @State private var showAdd = false

    var body: some View {
        List {
            ForEach(goals) { goal in
                VStack(alignment: .leading, spacing: 8) {
                    HStack { Text(goal.title).bold(); Spacer(); Text("\(Int(min(goal.current/max(goal.target,1),1)*100))%").foregroundStyle(.secondary) }
                    ProgressView(value: min(goal.current/max(goal.target,1),1)).tint(CCTheme.pink)
                    Text("\(goal.current.formatted()) / \(goal.target.formatted()) \(goal.unit)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
            .onDelete { offsets in
                offsets.map { goals[$0] }.forEach(modelContext.delete)
            }
        }
        .navigationTitle("Metas")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showAdd = true } label: { Image(systemName:"plus") } } }
        .sheet(isPresented: $showAdd) { NavigationStack { AddGoalView() } }
    }
}

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var target = ""
    @State private var unit = "$"
    @State private var type = "Ahorro"

    var body: some View {
        Form {
            TextField("Nombre de la meta", text: $title)
            TextField("Objetivo", text: $target).keyboardType(.decimalPad)
            Picker("Tipo", selection: $type) { ForEach(["Ahorro","Peso","Actividad","Personal"], id:\.self) { Text($0) } }
            TextField("Unidad", text: $unit)
            Button("Crear meta") {
                let value = Double(target.replacingOccurrences(of:",",with:".")) ?? 0
                if !title.isEmpty, value > 0 {
                    modelContext.insert(GoalItem(title:title,target:value,unit:unit,type:type))
                    dismiss()
                }
            }
        }
        .navigationTitle("Nueva meta")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar"){ dismiss() } } }
    }
}

struct MeasurementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @State private var waist = ""
    @State private var hip = ""
    @State private var arm = ""
    @State private var leg = ""
    @State private var chest = ""

    var body: some View {
        Form {
            Section("Nuevo registro (cm)") {
                TextField("Cintura", text: $waist).keyboardType(.decimalPad)
                TextField("Cadera", text: $hip).keyboardType(.decimalPad)
                TextField("Brazo", text: $arm).keyboardType(.decimalPad)
                TextField("Pierna", text: $leg).keyboardType(.decimalPad)
                TextField("Pecho", text: $chest).keyboardType(.decimalPad)
                Button("Guardar medidas") {
                    modelContext.insert(BodyMeasurement(
                        waist: d(waist), hip: d(hip), arm: d(arm), leg: d(leg), chest: d(chest)
                    ))
                    waist=""; hip=""; arm=""; leg=""; chest=""
                }
            }
            Section("Historial") {
                ForEach(measurements.prefix(12)) { m in
                    VStack(alignment:.leading) {
                        Text(m.date.formatted(date:.abbreviated,time:.omitted)).bold()
                        Text("Cintura \(v(m.waist)) · Cadera \(v(m.hip)) · Brazo \(v(m.arm)) · Pierna \(v(m.leg)) · Pecho \(v(m.chest))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Medidas")
    }

    private func d(_ s:String)->Double? { Double(s.replacingOccurrences(of:",",with:".")) }
    private func v(_ x:Double?)->String { x.map { "\($0.formatted(.number.precision(.fractionLength(1)))) cm" } ?? "—" }
}

struct GlobalCalendarView: View {
    @Query private var finances: [FinanceEntry]
    @Query private var weights: [WeightEntry]
    @Query private var activities: [ActivityEntry]
    @State private var selected = Date()

    var body: some View {
        Form {
            DatePicker("Día", selection: $selected, displayedComponents: .date)
                .datePickerStyle(.graphical)
            Section("Resumen del día") {
                LabeledContent("Movimientos", value: "\(finances.filter { Calendar.current.isDate($0.date, inSameDayAs:selected) }.count)")
                LabeledContent("Pesajes", value: "\(weights.filter { Calendar.current.isDate($0.date, inSameDayAs:selected) }.count)")
                LabeledContent("Actividades", value: "\(activities.filter { Calendar.current.isDate($0.date, inSameDayAs:selected) }.count)")
            }
        }
        .navigationTitle("Calendario")
    }
}

struct AlertsView: View {
    @Query(sort: \ActivityEntry.date, order: .reverse) private var activities:[ActivityEntry]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights:[WeightEntry]
    @Query private var finances:[FinanceEntry]
    @AppStorage("cc.monthlyBudget") private var budget=0.0

    var body: some View {
        List {
            if let last = activities.first {
                let days = Calendar.current.dateComponents([.day], from:last.date, to:.now).day ?? 0
                if days >= 2 {
                    Label("Pasaron \(days) días sin actividad física registrada.", systemImage:"figure.walk.motion")
                }
            } else {
                Label("Todavía no registraste actividad física.", systemImage:"figure.walk")
            }

            if let lastWeight = weights.first {
                let days = Calendar.current.dateComponents([.day], from:lastWeight.date, to:.now).day ?? 0
                if days >= 7 { Label("Hace \(days) días que no registrás un pesaje.", systemImage:"scalemass") }
            }

            if budget > 0 {
                let month = Calendar.current.dateInterval(of:.month,for:.now)
                let spent = finances.filter { ($0.type == .expense) && (month?.contains($0.date) ?? false) }.reduce(0){$0+$1.amount}
                let pct = Int((spent/budget)*100)
                Label("Presupuesto utilizado: \(pct)%", systemImage:"gauge.with.dots.needle.67percent")
            }
        }
        .navigationTitle("Avisos")
    }
}

struct SettingsView: View {
    @AppStorage("cc.faceID") private var faceID=false
    @AppStorage("cc.weightReminder") private var weightReminder=true
    @AppStorage("cc.monthlyBudget") private var budget=0.0
    @AppStorage("cc.targetWeight") private var targetWeight=0.0
    @AppStorage("cc.weeklyGoal") private var weeklyGoal=3

    var body: some View {
        Form {
            Section("Privacidad") {
                Toggle("Face ID", isOn:$faceID)
            }
            Section("Notificaciones") {
                Toggle("Recordatorio diario de peso", isOn:$weightReminder)
                    .onChange(of:weightReminder) { _, enabled in
                        if enabled { NotificationManager.shared.scheduleDailyWeightReminder() }
                        else { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:["weight.daily"]) }
                    }
                Button("Solicitar permisos de notificación") {
                    Task { await NotificationManager.shared.requestPermission() }
                }
            }
            Section("Objetivos") {
                TextField("Presupuesto mensual", value:$budget, format:.number).keyboardType(.decimalPad)
                TextField("Peso meta", value:$targetWeight, format:.number).keyboardType(.decimalPad)
                Stepper("Actividad: \(weeklyGoal) días/semana", value:$weeklyGoal, in:1...7)
            }
            Section("Datos") {
                Text("Todos los registros se guardan localmente en este iPhone mediante SwiftData.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ajustes")
    }
}

struct AboutView: View {
    var body: some View {
        ZStack {
            CCTheme.background.ignoresSafeArea()
            VStack(spacing:20) {
                Spacer()
                HeartLogo(size:90)
                Text("CRISTIAN CONTROL").font(.title.bold())
                Text("Tu bienestar, bajo control").foregroundStyle(.secondary)
                Text("Finanzas · Peso · Actividad · Hábitos · Metas · Estadísticas")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Versión 1.0").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Acerca de")
    }
}
