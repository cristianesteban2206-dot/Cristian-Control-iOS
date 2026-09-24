import SwiftUI

struct RootView: View {
    @AppStorage("cc.didOnboard") private var didOnboard = false
    @AppStorage("cc.faceID") private var faceIDEnabled = false
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSplash = true
    @State private var unlocked = false

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !didOnboard {
                OnboardingView()
            } else if faceIDEnabled && !unlocked {
                LockView(unlocked: $unlocked)
            } else {
                MainTabView()
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.easeInOut(duration: 0.45)) {
                showSplash = false
            }
            if !faceIDEnabled { unlocked = true }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active && faceIDEnabled {
                unlocked = false
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            CCTheme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                HeartLogo(size: 116)
                VStack(spacing: 5) {
                    Text("CRISTIAN")
                        .font(.system(size: 43, weight: .light, design: .rounded))
                        .tracking(8)
                        .foregroundStyle(CCTheme.ink)
                    Text("CONTROL")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .tracking(10)
                        .foregroundStyle(CCTheme.gradient)
                }
                Spacer()
                Text("Tu bienestar, bajo control")
                    .font(.system(.body, design: .rounded).italic())
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 56)
            }
            .padding()
        }
    }
}

struct LockView: View {
    @Binding var unlocked: Bool
    @State private var checking = false

    var body: some View {
        ZStack {
            CCTheme.background.ignoresSafeArea()
            VStack(spacing: 22) {
                HeartLogo(size: 72)
                Text("Cristian Control")
                    .font(.title.bold())
                Text("Tus datos están protegidos")
                    .foregroundStyle(.secondary)
                Button {
                    Task {
                        checking = true
                        unlocked = await Biometrics.authenticate()
                        checking = false
                    }
                } label: {
                    Label("Desbloquear con Face ID", systemImage: "faceid")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(CCTheme.gradient, in: Capsule())
                        .foregroundStyle(.white)
                }
                .disabled(checking)
            }
            .padding(28)
        }
        .task {
            checking = true
            unlocked = await Biometrics.authenticate()
            checking = false
        }
    }
}
