import Foundation

public enum MoveDirection: CaseIterable, Sendable {
    case up, down, left, right
}

public struct TwentyFortyEightEngine: Equatable, Sendable {
    public private(set) var board: [Int]
    public private(set) var score: Int
    private var nextSpawnIndex: Int

    public init(board: [Int] = [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], score: Int = 0, nextSpawnIndex: Int = 5) {
        precondition(board.count == 16, "2048 board must contain 16 cells")
        self.board = board
        self.score = score
        self.nextSpawnIndex = nextSpawnIndex
    }

    @discardableResult
    public mutating func move(_ direction: MoveDirection) -> Bool {
        let previous = board
        var gained = 0
        let lines = lineIndexes(for: direction)
        for line in lines {
            let values = line.map { board[$0] }
            let merged = merge(values)
            gained += merged.gained
            for (offset, index) in line.enumerated() {
                board[index] = merged.values[offset]
            }
        }
        guard board != previous else { return false }
        score += gained
        spawnTile()
        return true
    }

    public var hasWon: Bool { board.contains { $0 >= 2048 } }
    public var isFull: Bool { board.allSatisfy { $0 != 0 } }

    private func lineIndexes(for direction: MoveDirection) -> [[Int]] {
        switch direction {
        case .left: return (0..<4).map { row in (0..<4).map { row * 4 + $0 } }
        case .right: return (0..<4).map { row in (0..<4).reversed().map { row * 4 + $0 } }
        case .up: return (0..<4).map { col in (0..<4).map { $0 * 4 + col } }
        case .down: return (0..<4).map { col in (0..<4).reversed().map { $0 * 4 + col } }
        }
    }

    private func merge(_ values: [Int]) -> (values: [Int], gained: Int) {
        var compact = values.filter { $0 != 0 }
        var result: [Int] = []
        var gained = 0
        while compact.isEmpty == false {
            if compact.count >= 2 && compact[0] == compact[1] {
                let value = compact[0] * 2
                result.append(value)
                gained += value
                compact.removeFirst(2)
            } else {
                result.append(compact.removeFirst())
            }
        }
        result.append(contentsOf: Array(repeating: 0, count: max(0, 4 - result.count)))
        return (Array(result.prefix(4)), gained)
    }

    private mutating func spawnTile() {
        let empty = board.indices.filter { board[$0] == 0 }
        guard empty.isEmpty == false else { return }
        let index = empty[nextSpawnIndex % empty.count]
        board[index] = nextSpawnIndex.isMultiple(of: 7) ? 4 : 2
        nextSpawnIndex += 3
    }
}
