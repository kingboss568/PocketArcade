import SwiftUI
import SharedCore

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
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
    var body: some View {
        TabView {
            MainMenuView()
                .tabItem { Label("Arcade", systemImage: "gamecontroller.fill") }
            ScoreboardView()
                .tabItem { Label("Scores", systemImage: "trophy.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(ArcadeTheme.neonYellow)
    }
}

#Preview {
    AppRootView()
}
