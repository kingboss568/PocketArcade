import SpriteKit
import SwiftData
import SwiftUI
import SharedCore

/// 全螢幕遊戲容器：SpriteView 滿版，HUD 與按鈕全部在場景內，SwiftUI 不疊任何會擋觸控的元件。
struct GameHostView: View {
    let game: GameModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gameCenter: GameCenterService
    @State private var scene: BaseArcadeScene?
    @State private var sceneID = UUID()
    @State private var showCoach = false
    @State private var lastScore = 0
    @State private var lastLevel = 1

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let scene {
                SpriteView(scene: scene, preferredFramesPerSecond: 60)
                    .ignoresSafeArea()
                    .id(sceneID)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $showCoach) { ArcadeCoachView(game: game, recentScore: lastScore) }
        .onAppear { if scene == nil { rebuildScene() } }
        .onDisappear { saveProgress() }
    }

    private func rebuildScene() {
        let newScene = ArcadeSceneFactory.makeScene(for: game)
        newScene.onScoreChanged = { score in Task { @MainActor in lastScore = score } }
        newScene.onLevelChanged = { level in Task { @MainActor in lastLevel = level } }
        newScene.onGameOver = { score, level in
            Task { @MainActor in
                lastScore = score
                lastLevel = level
                saveProgress()
            }
        }
        newScene.onExit = { Task { @MainActor in dismiss() } }
        newScene.onRestart = { Task { @MainActor in rebuildScene() } }
        newScene.onRequestCoach = { Task { @MainActor in showCoach = true } }
        scene = newScene
        sceneID = UUID()
    }

    private func saveProgress() {
        guard lastScore > 0 else { return }
        do {
            let record = try GameProgressStore.record(score: lastScore, level: lastLevel, for: game, in: modelContext)
            gameCenter.submit(score: record.highScore, leaderboardID: game.leaderboardID)
        } catch {
            // 本機儲存失敗不阻斷遊戲流程
        }
    }
}
