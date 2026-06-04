import SpriteKit
import SwiftData
import SwiftUI
import SharedCore

struct GameHostView: View {
    let game: GameModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var gameCenter: GameCenterService
    @State private var scene: BaseArcadeScene
    @State private var currentScore = 0
    @State private var currentLevel = 1
    @State private var saveMessage: String?
    @State private var showCoach = false

    init(game: GameModel) {
        self.game = game
        _scene = State(initialValue: ArcadeSceneFactory.makeScene(for: game))
    }

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene, options: [.allowsTransparency]).ignoresSafeArea(edges: .bottom)
            VStack(spacing: 10) {
                HStack {
                    metric("Score", value: currentScore)
                    metric("Level", value: currentLevel)
                    Spacer()
                    Button { showCoach = true } label: { Label("Coach", systemImage: "sparkles") }
                        .buttonStyle(.borderedProminent).tint(ArcadeTheme.neonRed)
                }
                .font(.caption.monospaced().weight(.bold))
                .padding(.horizontal)
                if let saveMessage {
                    Text(saveMessage).font(.caption.monospaced()).foregroundStyle(ArcadeTheme.neonYellow)
                }
            }.padding(.top, 10)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("保存分數") { saveProgress() }
                Spacer()
                Text(game.title).font(.caption.monospaced().weight(.bold))
            }
        }
        .navigationTitle(game.englishTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCoach) { ArcadeCoachView(game: game, recentScore: currentScore) }
        .onAppear {
            scene.onScoreChanged = { score in Task { @MainActor in currentScore = score } }
            scene.onLevelChanged = { level in Task { @MainActor in currentLevel = level } }
        }
        .onDisappear { saveProgress() }
    }

    private func metric(_ label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased()).foregroundStyle(.white.opacity(0.7))
            Text("\(value)").foregroundStyle(ArcadeTheme.neonYellow)
        }.padding(8).background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }

    private func saveProgress() {
        do {
            let record = try GameProgressStore.record(score: currentScore, level: currentLevel, for: game, in: modelContext)
            gameCenter.submit(score: record.highScore, leaderboardID: game.leaderboardID)
            saveMessage = "Saved high score \(record.highScore)"
        } catch { saveMessage = "Save failed: \(error.localizedDescription)" }
    }
}
