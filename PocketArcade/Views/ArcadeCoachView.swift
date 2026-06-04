import SwiftUI
import SharedCore

struct ArcadeCoachView: View {
    let game: GameModel
    let recentScore: Int
    @Environment(\.dismiss) private var dismiss
    @State private var question = "我下一局怎麼提高分數？"
    @State private var answer = AIUnavailableMessage.text
    @State private var evidence: [RAGSearchResult] = []

    private let coach = FoundationModelsArcadeCoach()
    private let index = RAGIndexLoader.load()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                NeonPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Arcade Coach").font(ArcadeTheme.title).foregroundStyle(.white)
                        Text("AI 只負責摘要、整理與解釋；分數、解鎖、關卡與匯出全部由 deterministic Swift service 處理。")
                            .font(.caption.monospaced()).foregroundStyle(.white.opacity(0.72))
                    }
                }
                TextField("Ask for a tip", text: $question, axis: .vertical).textFieldStyle(.roundedBorder)
                Button("查詢本機攻略") { Task { await ask() } }.buttonStyle(.borderedProminent).tint(ArcadeTheme.neonYellow).foregroundStyle(.black)
                Text(answer).font(ArcadeTheme.body).foregroundStyle(.white).padding().background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                if evidence.isEmpty == false {
                    Text("Evidence").font(.headline.monospaced()).foregroundStyle(ArcadeTheme.neonCyan)
                    ForEach(evidence, id: \.chunk.id) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.chunk.title).font(.caption.monospaced().weight(.bold))
                            Text(result.snippet).font(.caption2.monospaced())
                        }.foregroundStyle(.white.opacity(0.75))
                    }
                }
                Spacer()
            }.padding().navigationTitle(game.title).toolbar { Button("關閉") { dismiss() } }.arcadeScreenBackground()
        }
    }

    private func ask() async {
        let searcher = LocalRAGSearchService(chunks: index.chunks)
        evidence = searcher.search(question + " " + game.title, limit: 3)
        let response = await coach.answer(AICoachRequest(gameTitle: game.title, recentScore: recentScore, question: question), evidence: evidence.map { $0.chunk.id })
        answer = response.text
    }
}
