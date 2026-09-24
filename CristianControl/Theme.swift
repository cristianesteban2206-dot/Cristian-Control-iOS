import SwiftUI

enum CCTheme {
    static let pink = Color(red: 0.88, green: 0.28, blue: 0.59)
    static let violet = Color(red: 0.48, green: 0.26, blue: 0.72)
    static let softPink = Color(red: 0.99, green: 0.92, blue: 0.96)
    static let softViolet = Color(red: 0.94, green: 0.91, blue: 0.99)
    static let ink = Color(red: 0.19, green: 0.13, blue: 0.23)

    static var gradient: LinearGradient {
        LinearGradient(colors: [pink, violet], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var background: LinearGradient {
        LinearGradient(
            colors: [Color.white, softPink.opacity(0.85), softViolet.opacity(0.75)],
            startPoint: .top,
            endPoint: .bottomTrailing
        )
    }
}

struct PremiumCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: CCTheme.violet.opacity(0.08), radius: 18, y: 8)
    }
}

struct HeartLogo: View {
    var size: CGFloat = 92

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.78))
                .frame(width: size * 1.25, height: size * 1.25)
                .shadow(color: CCTheme.pink.opacity(0.18), radius: 24)
            Image(systemName: "heart.fill")
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(CCTheme.gradient)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.28, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(y: size * 0.04)
                )
        }
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(CCTheme.gradient)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(CCTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
    }
}
