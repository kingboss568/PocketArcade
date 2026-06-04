import XCTest
@testable import PocketArcade

final class GomokuRuleServiceTests: XCTestCase {
    func testDetectsHorizontalFiveInARow() {
        var service = GomokuRuleService(size: 15)
        for column in 2...6 {
            XCTAssertTrue(service.place(.black, row: 7, column: column))
        }
        XCTAssertEqual(service.winner(after: 7, column: 6), .black)
    }

    func testRejectsOccupiedPosition() {
        var service = GomokuRuleService(size: 10)
        XCTAssertTrue(service.place(.white, row: 3, column: 3))
        XCTAssertFalse(service.place(.black, row: 3, column: 3))
    }
}
