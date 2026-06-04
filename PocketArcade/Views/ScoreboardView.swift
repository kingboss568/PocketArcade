import SwiftData
import SwiftUI
import SharedCore

struct ScoreboardView: View {
    @Query(sort: \GameProgress.highScore, order: .reverse) private var progresses: [GameProgress]
    private let games = GameCatalogLoader.load()

    var body: some View {
        NavigationStack {
            Group {
                if progresses.isEmpty {
                    EmptyStateView(title: "還沒有分數", message: "開一局 Brick Blitz 或 Snake EVO，這裡就會亮起你的街機紀錄。", systemImage: "trophy")
                } else {
                    List {
                        ForEach(games) { game in
                            let progress = progresses.first { $0.gameID == game.id.rawValue }
                            HStack {
                                VStack(alignment: .leading) { Text(game.title).font(.headline.monospaced()); Text(game.englishTitle).font(.caption.monospaced()).foregroundStyle(.secondary) }
                                Spacer()
                                Text("\(progress?.highScore ?? 0)").font(.title3.monospaced().weight(.black)).foregroundStyle(ArcadeTheme.neonRed)
                            }
                        }
                    }.scrollContentBackground(.hidden)
                }
            }.navigationTitle("Scoreboard").arcadeScreenBackground()
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: systemImage).font(.system(size: 58, weight: .black)).foregroundStyle(ArcadeTheme.neonYellow)
            Text(title).font(ArcadeTheme.title).foregroundStyle(.white)
            Text(message).font(ArcadeTheme.body).foregroundStyle(.white.opacity(0.72)).multilineTextAlignment(.center).padding(.horizontal)
        }.padding()
    }
}
