import SwiftUI
import SwiftData
import SharedCore

struct MainMenuView: View {
    let screenshotGameID: ArcadeGameID?
    let screenshotShowsPaywall: Bool
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var networkMonitor: NetworkMonitorService
    @Query private var progresses: [GameProgress]
    @State private var games = GameCatalogLoader.load()
    @State private var selectedGame: GameModel?
    @State private var paywallGame: GameModel?
    @State private var didApplyScreenshotLaunch = false

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    init(screenshotGameID: ArcadeGameID? = nil, screenshotShowsPaywall: Bool = false) {
        self.screenshotGameID = screenshotGameID
        self.screenshotShowsPaywall = screenshotShowsPaywall
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    hero
                    ForEach(ArcadeCategory.allCases, id: \.rawValue) { category in
                        let sectionGames = games.filter { $0.id.category == category }
                        if sectionGames.isEmpty == false {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 8) {
                                    Text(category.displayName)
                                        .font(.system(.title3, design: .monospaced).weight(.black))
                                        .foregroundStyle(.white)
                                    Text("\(sectionGames.count)")
                                        .font(.caption.monospaced().weight(.bold))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 8).padding(.vertical, 2)
                                        .background(Capsule().fill(ArcadeTheme.neonYellow))
                                }
                                LazyVGrid(columns: columns, spacing: 14) {
                                    ForEach(sectionGames) { game in
                                        GameCardView(game: game, progress: progress(for: game), isUnlocked: isUnlocked(game)) {
                                            if isUnlocked(game) { selectedGame = game } else { paywallGame = game }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(18)
            }
            .background(ArcadeTheme.midnight.ignoresSafeArea())
            .navigationTitle("Pocket Arcade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(ArcadeTheme.midnight, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { paywallGame = games.first(where: { !$0.isFree }) } label: {
                        Image(systemName: purchaseManager.entitlements.hasUnlockAll ? "checkmark.seal.fill" : "lock.open.fill")
                    }
                }
            }
            .navigationDestination(item: $selectedGame) { game in GameHostView(game: game) }
            .sheet(item: $paywallGame) { game in PaywallView(highlightedGame: game) }
            .onAppear(perform: applyScreenshotLaunchIfNeeded)
        }
        .arcadeScreenBackground()
    }

    private var hero: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                PixelBadge(networkMonitor.currentState == .offline ? "OFFLINE READY" : "NEON ARCADE")
                Text("20 games. One pocket. Zero boredom.")
                    .font(ArcadeTheme.headline)
                    .foregroundStyle(.white)
                Text("6 款免費開玩，14 款一次解鎖永久暢玩。分數與進度留在本機，離線也能玩。")
                    .font(ArcadeTheme.body)
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
    }

    private func progress(for game: GameModel) -> GameProgress? { progresses.first { $0.gameID == game.id.rawValue } }
    private func isUnlocked(_ game: GameModel) -> Bool { game.isFree || purchaseManager.entitlements.hasUnlockAll }

    private func applyScreenshotLaunchIfNeeded() {
        guard didApplyScreenshotLaunch == false else { return }
        didApplyScreenshotLaunch = true

        if let screenshotGameID, let game = games.first(where: { $0.id == screenshotGameID }) {
            selectedGame = game
        } else if screenshotShowsPaywall {
            paywallGame = games.first(where: { !$0.isFree })
        }
    }
}

struct GameCardView: View {
    let game: GameModel
    let progress: GameProgress?
    let isUnlocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    PixelBadge(game.isFree ? "FREE" : "PREMIUM", color: game.isFree ? ArcadeTheme.neonCyan : ArcadeTheme.neonYellow)
                    Spacer()
                    Image(systemName: isUnlocked ? "play.fill" : "lock.fill")
                        .foregroundStyle(isUnlocked ? ArcadeTheme.neonYellow : .white.opacity(0.55))
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(colors: [Color.arcadeAccent(for: game.id).opacity(0.34), Color.arcadeAccent(for: game.id).opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(height: 82)
                    Text(Self.iconText(for: game.id))
                        .font(.system(size: 42))
                        .shadow(color: Color.arcadeAccent(for: game.id).opacity(0.9), radius: 12)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.title)
                        .font(.system(.body, design: .monospaced).weight(.black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(game.englishTitle).font(.caption2.monospaced()).foregroundStyle(.white.opacity(0.6))
                    Text("HIGH \(progress?.highScore ?? UserDefaults.standard.integer(forKey: game.id.userDefaultsHighScoreKey))")
                        .font(.caption2.monospaced().weight(.bold)).foregroundStyle(ArcadeTheme.neonYellow)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ArcadeTheme.panel.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.arcadeAccent(for: game.id).opacity(0.65), lineWidth: 1))
                .shadow(color: Color.arcadeAccent(for: game.id).opacity(0.18), radius: 10, x: 0, y: 6)
        )
    }

    static func iconText(for id: ArcadeGameID) -> String {
        switch id {
        case .brickBlitz: return "🧱"
        case .snakeEVO: return "🐍"
        case .stackAttack: return "🏗️"
        case .frogDash: return "🐸"
        case .bubblePop: return "🫧"
        case .moleMania: return "🐹"
        case .pinballPro: return "🕹️"
        case .twentyFortyEight: return "🔢"
        case .asteroidAce: return "☄️"
        case .gomokuGo: return "⚫️"
        case .pongDuel: return "🏓"
        case .skyHop: return "☁️"
        case .rocketRush: return "🚀"
        case .laneRacer: return "🏎️"
        case .memoryMatch: return "🃏"
        case .reversiRoyale: return "⚪️"
        case .mineSweeper: return "💣"
        case .gemCrush: return "💎"
        case .invaderStorm: return "👾"
        case .fruitCatch: return "🍎"
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(PurchaseManager())
        .environmentObject(NetworkMonitorService())
}
