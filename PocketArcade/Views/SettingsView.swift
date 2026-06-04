import SwiftData
import SwiftUI
import SharedCore

struct SettingsView: View {
    @EnvironmentObject private var audioService: AudioService
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Query private var progresses: [GameProgress]
    @State private var exportText = ""
    @State private var showExport = false
    @State private var showPaywall = false
    private let games = GameCatalogLoader.load()
    private let exporter = ExportCoordinator()

    var body: some View {
        NavigationStack {
            Form {
                Section("Audio") { Toggle("音效", isOn: $audioService.isSoundOn) }
                Section("Purchases") {
                    HStack { Text("全部解鎖"); Spacer(); Text(purchaseManager.entitlements.hasUnlockAll ? "YES" : "NO") }
                    HStack { Text("去廣告"); Spacer(); Text(purchaseManager.entitlements.hasRemoveAds ? "YES" : "NO") }
                    Button("管理解鎖") { showPaywall = true }
                }
                Section("Export") {
                    Button("產生 CSV 預覽") { exportText = exporter.csv(rows: exportRows()); showExport = true }
                    Button("產生 PDF Data 測試") { let data = exporter.pdfData(rows: exportRows()); exportText = "PDF bytes: \(data.count)"; showExport = true }
                }
                Section("Disclaimer") { Text("遊戲分數與攻略僅供娛樂。AI 內容為輔助資訊，不構成專業意見。") }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .arcadeScreenBackground()
            .sheet(isPresented: $showExport) { ExportPreviewView(text: exportText) }
            .sheet(isPresented: $showPaywall) { PaywallView(highlightedGame: games[3]) }
        }
    }

    private func exportRows() -> [ArcadeScoreExportRow] {
        games.map { game in
            let progress = progresses.first { $0.gameID == game.id.rawValue }
            return GameProgressStore.row(for: game, progress: progress)
        }
    }
}

struct ExportPreviewView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView { Text(text).font(.caption.monospaced()).frame(maxWidth: .infinity, alignment: .leading).padding() }
                .navigationTitle("Export Preview").toolbar { Button("關閉") { dismiss() } }
        }
    }
}
