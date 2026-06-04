import Foundation

public enum GomokuStone: Int, Codable, Sendable {
    case empty = 0
    case black = 1
    case white = 2
}

public struct GomokuRuleService: Sendable {
    public let size: Int
    public private(set) var board: [GomokuStone]

    public init(size: Int = 15, board: [GomokuStone]? = nil) {
        self.size = size
        self.board = board ?? Array(repeating: .empty, count: size * size)
    }

    public func stone(at row: Int, column: Int) -> GomokuStone {
        guard row >= 0, row < size, column >= 0, column < size else { return .empty }
        return board[row * size + column]
    }

    @discardableResult
    public mutating func place(_ stone: GomokuStone, row: Int, column: Int) -> Bool {
        guard row >= 0, row < size, column >= 0, column < size else { return false }
        let index = row * size + column
        guard board[index] == .empty else { return false }
        board[index] = stone
        return true
    }

    public func winner(after row: Int, column: Int) -> GomokuStone? {
        let target = stone(at: row, column: column)
        guard target != .empty else { return nil }
        let directions = [(1, 0), (0, 1), (1, 1), (1, -1)]
        for direction in directions {
            let count = 1 + countStone(target, row: row, column: column, delta: direction) + countStone(target, row: row, column: column, delta: (-direction.0, -direction.1))
            if count >= 5 { return target }
        }
        return nil
    }

    public func forbiddenHintPositions(for stone: GomokuStone) -> [(row: Int, column: Int)] {
        guard stone == .black else { return [] }
        return (0..<size).flatMap { row in
            (0..<size).compactMap { column in
                guard self.stone(at: row, column: column) == .empty else { return nil }
                var copy = self
                _ = copy.place(.black, row: row, column: column)
                return copy.openThreeCount(row: row, column: column) >= 2 ? (row, column) : nil
            }
        }
    }

    private func countStone(_ target: GomokuStone, row: Int, column: Int, delta: (Int, Int)) -> Int {
        var row = row + delta.0
        var column = column + delta.1
        var total = 0
        while stone(at: row, column: column) == target {
            total += 1
            row += delta.0
            column += delta.1
        }
        return total
    }

    private func openThreeCount(row: Int, column: Int) -> Int {
        let directions = [(1, 0), (0, 1), (1, 1), (1, -1)]
        return directions.reduce(0) { partial, direction in
            let line = 1 + countStone(.black, row: row, column: column, delta: direction) + countStone(.black, row: row, column: column, delta: (-direction.0, -direction.1))
            return partial + (line == 3 ? 1 : 0)
        }
    }
}
