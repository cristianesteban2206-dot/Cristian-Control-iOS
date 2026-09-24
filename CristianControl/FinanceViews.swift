import SwiftUI
import SwiftData
import Charts

struct FinanceView: View {
    @Query(sort: \FinanceEntry.date, order: .reverse) private var entries: [FinanceEntry]
    @AppStorage("cc.monthlyBudget") private var monthlyBudget = 0.0
    @State private var showAdd = false

    private var monthEntries: [FinanceEntry] {
        guard let interval = Calendar.current.dateInterval(of: .month, for: .now) else { return [] }
        return entries.filter { interval.contains($0.date) }
    }

    private var spent: Double {
        monthEntries.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var income: Double {
        monthEntries.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ZStack {
            CCTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    PremiumCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Finanzas").font(.title2.bold())
                            Text((income - spent).ars)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("Balance de este mes").foregroundStyle(.secondary)
                            if monthlyBudget > 0 {
                                ProgressView(value: min(spent / monthlyBudget, 1))
                                    .tint(spent > monthlyBudget ? .red : CCTheme.pink)
                                Text("\(spent.ars) de \(monthlyBudget.ars)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack {
                        MetricPill(title: "Ingresos", value: income.ars, symbol: "arrow.down.circle.fill")
                        MetricPill(title: "Gastos", value: spent.ars, symbol: "arrow.up.circle.fill")
                    }

                    NavigationLink {
                        BudgetView()
                    } label: {
                        Label("Presupuesto mensual", systemImage: "gauge.with.dots.needle.67percent")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CCTheme.violet)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Movimientos recientes").font(.headline)
                            Spacer()
                            Button("Agregar") { showAdd = true }
                                .font(.subheadline.bold())
                        }
                        if entries.isEmpty {
                            ContentUnavailableView("Sin movimientos", systemImage: "creditcard", description: Text("Registrá tu primer gasto o ingreso."))
                                .frame(minHeight: 180)
                        } else {
                            ForEach(entries.prefix(10)) { entry in
                                NavigationLink {
                                    EditFinanceView(entry: entry)
                                } label: {
                                    HStack {
                                        Image(systemName: entry.type == .expense ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                            .foregroundColor(entry.type == .expense ? CCTheme.pink : Color.green)
                                        VStack(alignment: .leading) {
                                            Text(entry.note.isEmpty ? entry.category : entry.note)
                                                .foregroundStyle(CCTheme.ink)
                                            Text("\(entry.category) · \(entry.date.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text((entry.type == .expense ? "- " : "+ ") + entry.amount.ars)
                                            .font(.subheadline.bold())
                                            .foregroundColor(entry.type == .expense ? Color.primary : Color.green)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 22))
                }
                .padding()
            }
        }
        .navigationTitle("Finanzas")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showAdd) { NavigationStack { AddFinanceView() } }
    }
}

struct AddFinanceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FinanceEntry.date, order: .reverse) private var allEntries: [FinanceEntry]

    @AppStorage("cc.monthlyBudget") private var monthlyBudget = 0.0
    @State private var type: FinanceType = .expense
    @State private var amount = ""
    @State private var category = "Comida"
    @State private var note = ""
    @State private var payment = "Débito"
    @State private var date = Date()

    var body: some View {
        Form {
            Picker("Tipo", selection: $type) {
                ForEach(FinanceType.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .onChange(of: type) { _, newValue in
                category = FinanceCategory.list(for: newValue).first?.name ?? "Otros"
            }

            Section("Monto") {
                TextField("$ 0", text: $amount).keyboardType(.decimalPad)
            }
            Section("Detalle") {
                Picker("Categoría", selection: $category) {
                    ForEach(FinanceCategory.list(for: type)) { item in
                        Label(item.name, systemImage: item.symbol).tag(item.name)
                    }
                }
                Picker("Medio de pago", selection: $payment) {
                    ForEach(["Efectivo","Débito","Crédito","Transferencia"], id: \.self) { Text($0) }
                }
                TextField("Descripción opcional", text: $note)
                DatePicker("Fecha", selection: $date)
            }
            Section {
                Button("Guardar movimiento") { save() }
                    .frame(maxWidth: .infinity)
                    .disabled(parsedAmount == nil)
            }
        }
        .navigationTitle("Nuevo movimiento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
    }

    private var parsedAmount: Double? {
        let clean = amount.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        guard let value = Double(clean), value > 0 else { return nil }
        return value
    }

    private func save() {
        guard let value = parsedAmount else { return }
        modelContext.insert(FinanceEntry(amount: value, date: date, category: category, note: note, type: type, paymentMethod: payment))

        if type == .expense, monthlyBudget > 0 {
            guard let month = Calendar.current.dateInterval(of: .month, for: date) else { dismiss(); return }
            let previous = allEntries.filter { month.contains($0.date) && $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let total = previous + value
            let ratio = total / monthlyBudget
            if ratio >= 1 {
                NotificationManager.shared.notifyBudget(level: "Superaste el presupuesto", spent: total, budget: monthlyBudget)
            } else if ratio >= 0.9 {
                NotificationManager.shared.notifyBudget(level: "Llegaste al 90% del presupuesto", spent: total, budget: monthlyBudget)
            } else if ratio >= 0.75 {
                NotificationManager.shared.notifyBudget(level: "Ya usaste el 75% del presupuesto", spent: total, budget: monthlyBudget)
            }
        }
        dismiss()
    }
}

struct EditFinanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: FinanceEntry

    var body: some View {
        Form {
            Picker("Tipo", selection: Binding(get: { entry.type }, set: { entry.type = $0 })) {
                ForEach(FinanceType.allCases) { Text($0.rawValue).tag($0) }
            }
            TextField("Monto", value: $entry.amount, format: .number).keyboardType(.decimalPad)
            TextField("Categoría", text: $entry.category)
            TextField("Descripción", text: $entry.note)
            DatePicker("Fecha", selection: $entry.date)
            Button("Eliminar movimiento", role: .destructive) {
                modelContext.delete(entry)
                dismiss()
            }
        }
        .navigationTitle("Editar movimiento")
    }
}

struct BudgetView: View {
    @AppStorage("cc.monthlyBudget") private var budget = 0.0
    @State private var text = ""

    var body: some View {
        Form {
            Section("Presupuesto mensual") {
                TextField("Monto", text: $text)
                    .keyboardType(.decimalPad)
                Button("Guardar") {
                    budget = Double(text.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")) ?? budget
                }
            }
            Section {
                Text("Las alertas se muestran al 75%, 90% y 100% cuando registrás nuevos gastos.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Presupuesto")
        .onAppear { text = budget == 0 ? "" : String(format: "%.0f", budget) }
    }
}
