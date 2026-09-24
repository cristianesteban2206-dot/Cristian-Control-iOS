import Foundation
import LocalAuthentication

@MainActor
enum Biometrics {
    static func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancelar"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Desbloqueá Cristian Control para ver tus datos personales."
            )
        } catch {
            return false
        }
    }
}
