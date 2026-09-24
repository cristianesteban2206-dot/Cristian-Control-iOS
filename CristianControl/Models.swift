import Foundation
import SwiftData

enum FinanceType: String, CaseIterable, Identifiable {
    case expense = "Gasto"
    case income = "Ingreso"
    var id: String { rawValue }
}

enum ActivityKind: String, CaseIterable, Identifiable {
    case gym = "Gimnasio"
    case walk = "Caminata"
    case home = "Entrenamiento"
    case run = "Running"
    case bike = "Bicicleta"
    case yoga = "Yoga"
    case functional = "Funcional"
    case stretching = "Estiramiento"
    case other = "Otro"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .gym: return "dumbbell.fill"
        case .walk: return "figure.walk"
        case .home: return "figure.strengthtraining.traditional"
        case .run: return "figure.run"
        case .bike: return "bicycle"
        case .yoga: return "figure.mind.and.body"
        case .functional: return "figure.highintensity.intervaltraining"
        case .stretching: return "figure.cooldown"
        case .other: return "figure.mixed.cardio"
        }
    }
}

enum Mood: String, CaseIterable, Identifiable {
    case excellent = "Excelente"
    case good = "Bien"
    case normal = "Normal"
    case tired = "Cansado"
    case low = "Desmotivado"
    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .excellent: return "😁"
        case .good: return "🙂"
        case .normal: return "😐"
        case .tired: return "🥱"
        case .low: return "😔"
        }
    }
}

@Model
final class FinanceEntry {
    var id: UUID
    var amount: Double
    var date: Date
    var category: String
    var note: String
    var typeRaw: String
    var paymentMethod: String

    var type: FinanceType {
        get { FinanceType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    init(amount: Double, date: Date = .now, category: String, note: String = "", type: FinanceType, paymentMethod: String = "Débito") {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.category = category
        self.note = note
        self.typeRaw = type.rawValue
        self.paymentMethod = paymentMethod
    }
}

@Model
final class WeightEntry {
    var id: UUID
    var weight: Double
    var date: Date
    var note: String

    init(weight: Double, date: Date = .now, note: String = "") {
        self.id = UUID()
        self.weight = weight
        self.date = date
        self.note = note
    }
}

@Model
final class ActivityEntry {
    var id: UUID
    var kindRaw: String
    var date: Date
    var minutes: Int
    var intensity: String
    var note: String

    var kind: ActivityKind {
        get { ActivityKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    init(kind: ActivityKind, date: Date = .now, minutes: Int, intensity: String = "Moderada", note: String = "") {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.date = date
        self.minutes = minutes
        self.intensity = intensity
        self.note = note
    }
}

@Model
final class HabitEntry {
    var id: UUID
    var date: Date
    var waterGlasses: Int
    var sleepHours: Double
    var moodRaw: String

    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .normal }
        set { moodRaw = newValue.rawValue }
    }

    init(date: Date = .now, waterGlasses: Int = 0, sleepHours: Double = 0, mood: Mood = .normal) {
        self.id = UUID()
        self.date = date
        self.waterGlasses = waterGlasses
        self.sleepHours = sleepHours
        self.moodRaw = mood.rawValue
    }
}

@Model
final class BodyMeasurement {
    var id: UUID
    var date: Date
    var waist: Double?
    var hip: Double?
    var arm: Double?
    var leg: Double?
    var chest: Double?

    init(date: Date = .now, waist: Double? = nil, hip: Double? = nil, arm: Double? = nil, leg: Double? = nil, chest: Double? = nil) {
        self.id = UUID()
        self.date = date
        self.waist = waist
        self.hip = hip
        self.arm = arm
        self.leg = leg
        self.chest = chest
    }
}

@Model
final class GoalItem {
    var id: UUID
    var title: String
    var target: Double
    var current: Double
    var unit: String
    var type: String
    var dueDate: Date?

    init(title: String, target: Double, current: Double = 0, unit: String, type: String, dueDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.target = target
        self.current = current
        self.unit = unit
        self.type = type
        self.dueDate = dueDate
    }
}

struct FinanceCategory: Identifiable, Hashable {
    let name: String
    let symbol: String
    var id: String { name }

    static let expenses: [FinanceCategory] = [
        .init(name: "Comida", symbol: "fork.knife"),
        .init(name: "Supermercado", symbol: "cart.fill"),
        .init(name: "Combustible", symbol: "fuelpump.fill"),
        .init(name: "Hogar", symbol: "house.fill"),
        .init(name: "Ropa", symbol: "tshirt.fill"),
        .init(name: "Salud", symbol: "cross.case.fill"),
        .init(name: "Transporte", symbol: "car.fill"),
        .init(name: "Servicios", symbol: "bolt.fill"),
        .init(name: "Tarjetas", symbol: "creditcard.fill"),
        .init(name: "Entretenimiento", symbol: "gamecontroller.fill"),
        .init(name: "Otros", symbol: "ellipsis.circle.fill")
    ]

    static let incomes: [FinanceCategory] = [
        .init(name: "Sueldo", symbol: "banknote.fill"),
        .init(name: "Venta", symbol: "tag.fill"),
        .init(name: "Transferencia", symbol: "arrow.left.arrow.right"),
        .init(name: "Extra", symbol: "plus.circle.fill"),
        .init(name: "Otros", symbol: "ellipsis.circle.fill")
    ]

    static func list(for type: FinanceType) -> [FinanceCategory] {
        type == .expense ? expenses : incomes
    }
}

extension Double {
    var ars: String {
        formatted(.currency(code: "ARS").locale(Locale(identifier: "es_AR")))
    }
    var kg: String {
        "\(formatted(.number.precision(.fractionLength(1)))) kg"
    }
}
