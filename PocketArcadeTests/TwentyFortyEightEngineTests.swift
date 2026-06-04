import XCTest
@testable import PocketArcade

final class TwentyFortyEightEngineTests: XCTestCase {
    func testMoveLeftMergesEqualTilesAndAddsDeterministicSpawn() {
        var engine = TwentyFortyEightEngine(board: [2, 2, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], score: 0, nextSpawnIndex: 2)
        XCTAssertTrue(engine.move(.left))
        XCTAssertEqual(engine.score, 12)
        XCTAssertEqual(Array(engine.board.prefix(4)), [4, 8, 0, 0])
        XCTAssertEqual(engine.board.filter { $0 == 2 }.count, 1)
    }

    func testMoveReturnsFalseWhenBoardDoesNotChange() {
        var engine = TwentyFortyEightEngine(board: [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2, 4, 8, 16, 32, 64])
        XCTAssertFalse(engine.move(.left))
    }
}
