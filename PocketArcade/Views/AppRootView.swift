import SwiftUI
import SharedCore

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    private let screenshot = ScreenshotLaunchConfiguration.current

    var body: some View {
        Group {
            if hasCompletedOnboarding || screenshot.isEnabled {
                MainTabView(
                    initialTab: screenshot.initialTab,
                    screenshotGameID: screenshot.gameID,
                    screenshotShowsPaywall: screenshot.showsPaywall
                )
            } else {
                OnboardingView {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.86)) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
        .arcadeScreenBackground()
    }
}

struct MainTabView: View {
    @State private var selectedTab: Int
    let screenshotGameID: ArcadeGameID?
    let screenshotShowsPaywall: Bool

    init(initialTab: Int = 0, screenshotGameID: ArcadeGameID? = nil, screenshotShowsPaywall: Bool = false) {
        _selectedTab = State(initialValue: initialTab)
        self.screenshotGameID = screenshotGameID
        self.screenshotShowsPaywall = screenshotShowsPaywall
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MainMenuView(screenshotGameID: screenshotGameID, screenshotShowsPaywall: screenshotShowsPaywall)
                .tabItem { Label("Arcade", systemImage: "gamecontroller.fill") }
                .tag(0)
            ScoreboardView()
                .tabItem { Label("Scores", systemImage: "trophy.fill") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .tint(ArcadeTheme.neonYellow)
    }
}

private struct ScreenshotLaunchConfiguration {
    let isEnabled: Bool
    let initialTab: Int
    let gameID: ArcadeGameID?
    let showsPaywall: Bool

    static var current: ScreenshotLaunchConfiguration {
        let arguments = CommandLine.arguments
        let isEnabled = arguments.contains("-screenshot-mode")
        return ScreenshotLaunchConfiguration(
            isEnabled: isEnabled,
            initialTab: integerValue(after: "-screenshot-tab", in: arguments) ?? 0,
            gameID: gameID(after: "-screenshot-game", in: arguments),
            showsPaywall: arguments.contains("-screenshot-paywall")
        )
    }

    private static func integerValue(after flag: String, in arguments: [String]) -> Int? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return Int(arguments[index + 1])
    }

    private static func gameID(after flag: String, in arguments: [String]) -> ArcadeGameID? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return ArcadeGameID(rawValue: arguments[index + 1])
    }
}

#Preview {
    AppRootView()
}
