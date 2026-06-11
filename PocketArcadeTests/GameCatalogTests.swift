import XCTest
@testable import PocketArcade

final class GameCatalogTests: XCTestCase {
    func testCatalogHasTwentyGamesWithSixFreeEntries() {
        let games = GameCatalogLoader.fallback
        XCTAssertEqual(games.count, 20)
        XCTAssertEqual(games.filter(\.isFree).count, 6)
        XCTAssertEqual(games.filter { !$0.isFree }.count, 14)
        XCTAssertEqual(Set(games.map(\.id)).count, ArcadeGameID.allCases.count)
    }

    func testLeaderboardIDsAreUnique() {
        let leaderboardIDs = GameCatalogLoader.fallback.map(\.leaderboardID)
        XCTAssertEqual(Set(leaderboardIDs).count, leaderboardIDs.count)
    }
}
