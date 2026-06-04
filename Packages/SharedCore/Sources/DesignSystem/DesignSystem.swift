import SwiftUI

public enum ArcadeTheme {
    public static let midnight = Color(red: 0.10, green: 0.10, blue: 0.18)
    public static let neonRed = Color(red: 0.91, green: 0.27, blue: 0.38)
    public static let neonYellow = Color(red: 0.96, green: 0.65, blue: 0.14)
    public static let neonCyan = Color(red: 0.20, green: 0.88, blue: 0.95)
    public static let panel = Color(red: 0.14, green: 0.14, blue: 0.25)

    public static let headline = Font.system(.largeTitle, design: .monospaced).weight(.black)
    public static let title = Font.system(.title2, design: .monospaced).weight(.bold)
    public static let body = Font.system(.body, design: .monospaced)
}

public struct NeonPanel<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(ArcadeTheme.panel.opacity(0.86))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(LinearGradient(colors: [ArcadeTheme.neonCyan, ArcadeTheme.neonRed], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                    )
                    .shadow(color: ArcadeTheme.neonRed.opacity(0.30), radius: 18, x: 0, y: 10)
            )
    }
}

public struct PixelBadge: View {
    private let text: String
    private let color: Color

    public init(_ text: String, color: Color = ArcadeTheme.neonYellow) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color, in: Capsule())
    }
}

public extension View {
    func arcadeScreenBackground() -> some View {
        background(
            ZStack {
                ArcadeTheme.midnight.ignoresSafeArea()
                RadialGradient(colors: [ArcadeTheme.neonRed.opacity(0.28), .clear], center: .topTrailing, startRadius: 20, endRadius: 420).ignoresSafeArea()
                LinearGradient(colors: [.clear, ArcadeTheme.neonCyan.opacity(0.18)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            }
        )
    }
}
