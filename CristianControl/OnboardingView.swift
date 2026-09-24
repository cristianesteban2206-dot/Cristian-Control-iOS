import SwiftUI

struct OnboardingView: View {
    @AppStorage("cc.didOnboard") private var didOnboard = false
    @AppStorage("cc.name") private var name = "Cristian"
    @AppStorage("cc.monthlyBudget") private var monthlyBudget = 0.0
    @AppStorage("cc.targetWeight") private var targetWeight = 0.0
    @AppStorage("cc.weeklyGoal") private var weeklyGoal = 3
    @AppStorage("cc.faceID") private var faceIDEnabled = false
    @AppStorage("cc.weightReminder") private var weightReminder = true

    @State private var budgetText = ""
    @State private var weightText = ""
    @State private var page = 0

    var body: some View {
        ZStack {
            CCTheme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                HStack {
                    HeartLogo(size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CRISTIAN CONTROL").font(.headline.bold())
                        Text("Configuración inicial").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Spacer()

                Group {
                    if page == 0 {
                        VStack(spacing: 18) {
                            Text("Todo en un solo lugar")
                                .font(.largeTitle.bold())
                                .multilineTextAlignment(.center)
                            Text("Finanzas, peso, actividad, hábitos, metas, estadísticas y recordatorios.")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 90))
                                .foregroundStyle(CCTheme.gradient)
                        }
                    } else if page == 1 {
                        VStack(spacing: 18) {
                            Text("Tus objetivos")
                                .font(.largeTitle.bold())
                            TextField("Presupuesto mensual", text: $budgetText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            TextField("Peso meta (kg)", text: $weightText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            Stepper("Actividad: \(weeklyGoal) días por semana", value: $weeklyGoal, in: 1...7)
                        }
                    } else {
                        VStack(spacing: 18) {
                            Text("Privacidad y avisos")
                                .font(.largeTitle.bold())
                            Toggle("Proteger con Face ID", isOn: $faceIDEnabled)
                            Toggle("Recordatorio diario de peso", isOn: $weightReminder)
                            Text("La app puede avisarte si pasan más de 2 días sin registrar actividad física.")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 28))

                Spacer()

                Button(page == 2 ? "Comenzar" : "Continuar") {
                    if page < 2 {
                        withAnimation { page += 1 }
                    } else {
                        monthlyBudget = parse(budgetText)
                        targetWeight = parse(weightText)
                        didOnboard = true
                        Task {
                            await NotificationManager.shared.requestPermission()
                            NotificationManager.shared.scheduleInactivityReminder()
                            if weightReminder {
                                NotificationManager.shared.scheduleDailyWeightReminder()
                            }
                        }
                    }
                }
                .buttonStyle(PremiumButtonStyle())
            }
            .padding(24)
        }
    }

    private func parse(_ text: String) -> Double {
        let cleaned = text.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0
    }
}

struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(CCTheme.gradient.opacity(configuration.isPressed ? 0.8 : 1), in: Capsule())
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
