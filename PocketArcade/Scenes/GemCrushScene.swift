import SpriteKit

/// 寶石消消樂：滑動交換相鄰寶石、三連消除、連鎖掉落，步數內達標過關。
final class GemCrushScene: BaseArcadeScene {

    private let columns = 7
    private let rows = 8
    private var board: [[Int]] = []          // [col][row]，row 0 在下面，-1 = 空
    private var gemNodes: [[SKNode?]] = []
    private var cellSize: CGFloat = 0
    private var boardOrigin: CGPoint = .zero
    private var swipeStart: CGPoint?
    private var swipeCell: (col: Int, row: Int)?
    private var busy = false
    private var movesLeft = 20
    private var target = 600
    private var infoLabel: SKLabelNode!
    private var comboChain = 0

    private let gemEmojis = ["💎", "🔶", "💜", "🍀", "⭐️", "🔴"]
    private var gemKindCount: Int { min(5 + (level >= 4 ? 1 : 0), gemEmojis.count) }
    private let gemColors: [UIColor] = [.cyan, .orange, .purple, .green, .yellow, .red]

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.14, green: 0.05, blue: 0.18, alpha: 1),
                                    bottom: UIColor(red: 0.05, green: 0.02, blue: 0.08, alpha: 1))
        ArcadeFX.addStarfield(to: self, count: 30)
    }

    override func setupGame() {
        let margin: CGFloat = 14
        cellSize = min((size.width - margin * 2) / CGFloat(columns),
                       (playTop - playBottom - 60) / CGFloat(rows))
        let boardWidth = cellSize * CGFloat(columns)
        let boardHeight = cellSize * CGFloat(rows)
        boardOrigin = CGPoint(x: (size.width - boardWidth) / 2,
                              y: playBottom + 46 + (playTop - playBottom - 60 - boardHeight) / 2)

        let frame = ArcadeFX.roundedRect(size: CGSize(width: boardWidth + 12, height: boardHeight + 12), radius: 12,
                                         fill: SKColor.white.withAlphaComponent(0.06),
                                         stroke: accent.withAlphaComponent(0.55), lineWidth: 1.5)
        frame.position = CGPoint(x: size.width / 2, y: boardOrigin.y + boardHeight / 2)
        gameLayer.addChild(frame)

        infoLabel = ArcadeFX.label("", size: 15, color: .white.withAlphaComponent(0.85), font: "AvenirNext-Bold")
        infoLabel.position = CGPoint(x: size.width / 2, y: playBottom + 16)
        infoLabel.zPosition = 100
        gameLayer.addChild(infoLabel)

        startLevel()
    }

    private func startLevel() {
        movesLeft = 20
        target = score + 500 + level * 220
        updateInfo()

        gemNodes.flatMap { $0 }.forEach { $0?.removeFromParent() }
        board = Array(repeating: Array(repeating: -1, count: rows), count: columns)
        gemNodes = Array(repeating: Array(repeating: nil, count: rows), count: columns)

        for col in 0..<columns {
            for row in 0..<rows {
                var kind: Int
                repeat {
                    kind = Int.random(in: 0..<gemKindCount)
                } while createsMatch(col: col, row: row, kind: kind)
                board[col][row] = kind
                let node = makeGem(kind: kind)
                node.position = cellCenter(col: col, row: row)
                gameLayer.addChild(node)
                gemNodes[col][row] = node
            }
        }
    }

    private func createsMatch(col: Int, row: Int, kind: Int) -> Bool {
        if col >= 2, board[col - 1][row] == kind, board[col - 2][row] == kind { return true }
        if row >= 2, board[col][row - 1] == kind, board[col][row - 2] == kind { return true }
        return false
    }

    private func makeGem(kind: Int) -> SKNode {
        let node = ArcadeFX.emojiNode(gemEmojis[kind], size: cellSize * 0.68)
        node.zPosition = 10
        return node
    }

    private func cellCenter(col: Int, row: Int) -> CGPoint {
        CGPoint(x: boardOrigin.x + cellSize / 2 + CGFloat(col) * cellSize,
                y: boardOrigin.y + cellSize / 2 + CGFloat(row) * cellSize)
    }

    private func updateInfo() {
        infoLabel.text = "目標 \(target)　剩 \(movesLeft) 步"
    }

    // MARK: - Touch

    override func gameTouchBegan(at point: CGPoint) {
        guard busy == false else { return }
        swipeStart = point
        let col = Int((point.x - boardOrigin.x) / cellSize)
        let row = Int((point.y - boardOrigin.y) / cellSize)
        swipeCell = (col >= 0 && col < columns && row >= 0 && row < rows) ? (col, row) : nil
    }

    override func gameTouchMoved(to point: CGPoint, previous: CGPoint) {
        guard busy == false, let start = swipeStart, let cell = swipeCell else { return }
        let dx = point.x - start.x
        let dy = point.y - start.y
        guard max(abs(dx), abs(dy)) > cellSize * 0.4 else { return }
        let direction: (Int, Int) = abs(dx) > abs(dy) ? (dx > 0 ? 1 : -1, 0) : (0, dy > 0 ? 1 : -1)
        swipeStart = nil
        swipeCell = nil
        attemptSwap(from: cell, direction: direction)
    }

    private func attemptSwap(from cell: (col: Int, row: Int), direction: (Int, Int)) {
        let other = (col: cell.col + direction.0, row: cell.row + direction.1)
        guard other.col >= 0, other.col < columns, other.row >= 0, other.row < rows else { return }
        busy = true
        ArcadeFX.Haptic.light()

        swapData(cell, other)
        let nodeA = gemNodes[cell.col][cell.row]!
        let nodeB = gemNodes[other.col][other.row]!
        let moveA = SKAction.move(to: cellCenter(col: cell.col, row: cell.row), duration: 0.14)
        let moveB = SKAction.move(to: cellCenter(col: other.col, row: other.row), duration: 0.14)
        moveA.timingMode = .easeInEaseOut
        moveB.timingMode = .easeInEaseOut
        nodeA.run(moveA)
        nodeB.run(moveB)

        run(.sequence([.wait(forDuration: 0.16), .run { [weak self] in
            guard let self else { return }
            if self.findMatches().isEmpty {
                // 換回去
                self.swapData(cell, other)
                let backA = SKAction.move(to: self.cellCenter(col: cell.col, row: cell.row), duration: 0.14)
                let backB = SKAction.move(to: self.cellCenter(col: other.col, row: other.row), duration: 0.14)
                self.gemNodes[cell.col][cell.row]?.run(backA)
                self.gemNodes[other.col][other.row]?.run(backB)
                self.busy = false
            } else {
                self.movesLeft -= 1
                self.updateInfo()
                self.comboChain = 0
                self.resolveMatches()
            }
        }]))
    }

    private func swapData(_ a: (col: Int, row: Int), _ b: (col: Int, row: Int)) {
        let tempKind = board[a.col][a.row]
        board[a.col][a.row] = board[b.col][b.row]
        board[b.col][b.row] = tempKind
        let tempNode = gemNodes[a.col][a.row]
        gemNodes[a.col][a.row] = gemNodes[b.col][b.row]
        gemNodes[b.col][b.row] = tempNode
    }

    // MARK: - Match resolution

    private func findMatches() -> Set<Int> {
        var matched = Set<Int>()
        func key(_ col: Int, _ row: Int) -> Int { col * 100 + row }
        // 橫向
        for row in 0..<rows {
            var runStart = 0
            for col in 1...columns {
                let same = col < columns && board[col][row] == board[runStart][row] && board[runStart][row] >= 0
                if same == false {
                    if col - runStart >= 3 {
                        for c in runStart..<col { matched.insert(key(c, row)) }
                    }
                    runStart = col
                }
            }
        }
        // 縱向
        for col in 0..<columns {
            var runStart = 0
            for row in 1...rows {
                let same = row < rows && board[col][row] == board[col][runStart] && board[col][runStart] >= 0
                if same == false {
                    if row - runStart >= 3 {
                        for r in runStart..<row { matched.insert(key(col, r)) }
                    }
                    runStart = row
                }
            }
        }
        return matched
    }

    private func resolveMatches() {
        let matches = findMatches()
        if matches.isEmpty {
            busy = false
            checkLevelState()
            return
        }
        comboChain += 1
        let multiplier = min(comboChain, 5)
        let points = matches.count * 10 * multiplier
        addScore(points)
        if comboChain >= 2 {
            flash("連鎖 ×\(comboChain)！", color: .systemYellow, fontSize: 22)
        }
        ArcadeFX.Haptic.medium()

        for key in matches {
            let col = key / 100
            let row = key % 100
            let kind = board[col][row]
            if let node = gemNodes[col][row] {
                ArcadeFX.burst(in: gameLayer, at: node.position, color: gemColors[max(kind, 0)], count: 8, speed: 70)
                node.run(.sequence([.group([.scale(to: 0.1, duration: 0.18), .fadeOut(withDuration: 0.18)]), .removeFromParent()]))
            }
            board[col][row] = -1
            gemNodes[col][row] = nil
        }

        run(.sequence([.wait(forDuration: 0.22), .run { [weak self] in self?.collapseAndRefill() }]))
    }

    private func collapseAndRefill() {
        var longestDrop = 0
        for col in 0..<columns {
            var writeRow = 0
            for row in 0..<rows where board[col][row] >= 0 {
                if row != writeRow {
                    board[col][writeRow] = board[col][row]
                    board[col][row] = -1
                    let node = gemNodes[col][row]
                    gemNodes[col][writeRow] = node
                    gemNodes[col][row] = nil
                    let drop = SKAction.move(to: cellCenter(col: col, row: writeRow), duration: 0.07 * Double(row - writeRow))
                    drop.timingMode = .easeIn
                    node?.run(drop)
                    longestDrop = max(longestDrop, row - writeRow)
                }
                writeRow += 1
            }
            // 補新寶石
            var spawnOffset = 1
            for row in writeRow..<rows {
                let kind = Int.random(in: 0..<gemKindCount)
                board[col][row] = kind
                let node = makeGem(kind: kind)
                node.position = CGPoint(x: cellCenter(col: col, row: row).x,
                                        y: boardOrigin.y + cellSize * CGFloat(rows) + cellSize * CGFloat(spawnOffset))
                gameLayer.addChild(node)
                gemNodes[col][row] = node
                let fallDistance = rows - row + spawnOffset
                let drop = SKAction.move(to: cellCenter(col: col, row: row), duration: 0.06 * Double(fallDistance))
                drop.timingMode = .easeIn
                node.run(drop)
                longestDrop = max(longestDrop, fallDistance)
                spawnOffset += 1
            }
        }

        run(.sequence([.wait(forDuration: 0.08 * Double(longestDrop) + 0.1), .run { [weak self] in
            self?.resolveMatches()
        }]))
    }

    private func checkLevelState() {
        if score >= target {
            level += 1
            addScore(movesLeft * 20)
            flash("過關！剩餘步數 ×20 加分", color: accent, fontSize: 22)
            ArcadeFX.Haptic.success()
            run(.sequence([.wait(forDuration: 1.0), .run { [weak self] in self?.startLevel() }]))
        } else if movesLeft <= 0 {
            endGame(message: "步數用完！")
        }
    }
}
