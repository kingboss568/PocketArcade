import SwiftUI
import SwiftData
import SharedCore

struct MainMenuView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var networkMonitor: NetworkMonitorService
    @Query private var progresses: [GameProgress]
    @State private var games = GameCatalogLoader.load()
    @State private var selectedGame: GameModel?
    @State private var paywallGame: GameModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 168), spacing: 16)], spacing: 16) {
                        ForEach(games) { game in
                            GameCardView(game: game, progress: progress(for: game), isUnlocked: isUnlocked(game)) {
                                if isUnlocked(game) { selectedGame = game } else { paywallGame = game }
                            }
                        }
                    }
                    aiFallbackNotice
                }
                .padding(20)
            }
            .navigationTitle("Pocket Arcade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { paywallGame = games.first(where: { !$0.isFree }) } label: {
                        Image(systemName: purchaseManager.entitlements.hasUnlockAll ? "checkmark.seal.fill" : "lock.open.fill")
                    }
                }
            }
            .navigationDestination(item: $selectedGame) { game in GameHostView(game: game) }
            .sheet(item: $paywallGame) { game in PaywallView(highlightedGame: game) }
        }
        .arcadeScreenBackground()
    }

    private var hero: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                PixelBadge(networkMonitor.currentState == .offline ? "OFFLINE READY" : "NEON ARCADE")
                Text("10 games. One pocket. Zero boredom.")
                    .font(ArcadeTheme.headline)
                    .foregroundStyle(.white)
                Text("3 款免費開玩，7 款用 StoreKit 2 一次解鎖。分數、進度與設定預設留在本機 SwiftData。")
                    .font(ArcadeTheme.body)
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
    }

    private var aiFallbackNotice: some View {
        Text("Arcade Coach：AI 功能目前不可用；所有核心遊戲、分數、解鎖與匯出流程可照常使用。")
            .font(.footnote.monospaced())
            .foregroundStyle(.white.opacity(0.66))
            .padding(.bottom, 20)
    }

    private func progress(for game: GameModel) -> GameProgress? { progresses.first { $0.gameID == game.id.rawValue } }
    private func isUnlocked(_ game: GameModel) -> Bool { game.isFree || purchaseManager.entitlements.hasUnlockAll }
}

struct GameCardView: View {
    let game: GameModel
    let progress: GameProgress?
    let isUnlocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    PixelBadge(game.isFree ? "FREE" : "PREMIUM", color: game.isFree ? ArcadeTheme.neonCyan : ArcadeTheme.neonYellow)
                    Spacer()
                    Image(systemName: isUnlocked ? "play.fill" : "lock.fill")
                        .foregroundStyle(isUnlocked ? ArcadeTheme.neonYellow : .white.opacity(0.55))
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.arcadeAccent(for: game.id).opacity(0.22))
                        .frame(height: 92)
                    Text(iconText(for: game.id))
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                        .shadow(color: Color.arcadeAccent(for: game.id), radius: 14)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.title).font(.system(.title3, design: .monospaced).weight(.black)).foregroundStyle(.white)
                    Text(game.englishTitle).font(.caption.monospaced()).foregroundStyle(.white.opacity(0.65))
                    Text("High \(progress?.highScore ?? UserDefaults.standard.integer(forKey: game.id.userDefaultsHighScoreKey))")
                        .font(.caption.monospaced().weight(.bold)).foregroundStyle(ArcadeTheme.neonYellow)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white.opacity(0.08)).overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.arcadeAccent(for: game.id).opacity(0.8), lineWidth: 1)))
    }

    private func iconText(for id: ArcadeGameID) -> String {
        switch id {
        case .brickBlitz: return "▦"
        case .snakeEVO: return "S"
        case .stackAttack: return "▣"
        case .frogDash: return "F"
        case .bubblePop: return "○"
        case .moleMania: return "M"
        case .pinballPro: return "P"
        case .twentyFortyEight: return "2K"
        case .asteroidAce: return "A"
        case .gomokuGo: return "五"
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(PurchaseManager())
        .environmentObject(NetworkMonitorService())
}
