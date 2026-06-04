import Foundation
import Combine
import GameKit

@MainActor
final class GameCenterService: NSObject, ObservableObject {
    static let shared = GameCenterService()
    @Published private(set) var isAuthenticated = false
    @Published var lastError: String?

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] _, error in
            Task { @MainActor in
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self?.lastError = error?.localizedDescription
            }
        }
    }

    func submit(score: Int, leaderboardID: String) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { [weak self] error in
            if let error {
                Task { @MainActor in self?.lastError = error.localizedDescription }
            }
        }
    }
}
