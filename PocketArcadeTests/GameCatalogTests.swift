import XCTest
@testable import PocketArcade

final class GameCatalogTests: XCTestCase {
    func testCatalogHasTenGamesWithThreeFreeEntries() {
        let games = GameCatalogLoader.fallback
        XCTAssertEqual(games.count, 10)
        XCTAssertEqual(games.filter(\.isFree).count, 3)
        XCTAssertEqual(games.filter { !$0.isFree }.count, 7)
    }

    func testLeaderboardIDsAreUnique() {
        let leaderboardIDs = GameCatalogLoader.fallback.map(\.leaderboardID)
        XCTAssertEqual(Set(leaderboardIDs).count, leaderboardIDs.count)
    }
}
