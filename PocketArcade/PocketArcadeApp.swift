import SwiftUI
import SwiftData

@main
struct PocketArcadeApp: App {
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var networkMonitor = NetworkMonitorService()
    @StateObject private var audioService = AudioService()
    @StateObject private var gameCenter = GameCenterService.shared

    private let modelContainer: ModelContainer = {
        let schema = Schema([GameProgress.self, PlayerPreference.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(purchaseManager)
                .environmentObject(networkMonitor)
                .environmentObject(audioService)
                .environmentObject(gameCenter)
                .modelContainer(modelContainer)
                .task {
                    purchaseManager.start()
                    gameCenter.authenticate()
                }
        }
    }
}
