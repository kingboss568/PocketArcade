import SpriteKit

/// 連線五子棋：13 路棋盤、與啟發式 AI 對弈、最後落子標記。
final class GomokuGoScene: BaseArcadeScene {

    private let boardSize = 13
    private var board: [[Int]] = []   // 0 空、1 玩家(黑)、2 AI(白)
    private var stoneNodes: [SKNode] = []
    private var cellSize: CGFloat = 0
    private var boardOrigin: CGPoint = .zero
    private var playerTurn = true
    private var moveCount = 0
    private var lastMoveMarker: SKShapeNode?
    private var thinking = false
    private var statusLabel: SKLabelNode!
    private var wins = 0

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.12, green: 0.09, blue: 0.05, alpha: 1),
                                    bottom: UIColor(red: 0.05, green: 0.04, blue: 0.02, alpha: 1))
    }

    override func setupGame() {
        board = Array(repeating: Array(repeating: 0, count: boardSize), count: boardSize)
        let boardWidth = size.width - 24
        cellSize = boardWidth / CGFloat(boardSize)
        let boardY = (playTop + playBottom) / 2 - boardWidth / 2
        boardOrigin = CGPoint(x: 12 + cellSize / 2, y: boardY + cellSize / 2)

        // 木紋棋盤
        let wood = ArcadeFX.roundedRect(size: CGSize(width: boardWidth + 8, height: boardWidth + 8), radius: 10,
                                        fill: SKColor(red: 0.72, green: 0.55, blue: 0.34, alpha: 1),
                                        stroke: SKColor(red: 0.45, green: 0.32, blue: 0.18, alpha: 1), lineWidth: 3)
        wood.position = CGPoint(x: size.width / 2, y: boardY + boardWidth / 2)
        gameLayer.addChild(wood)

        // 格線
        let lines = SKShapeNode()
        let path = CGMutablePath()
        for i in 0..<boardSize {
            let offset = CGFloat(i) * cellSize
            path.move(to: CGPoint(x: boardOrigin.x, y: boardOrigin.y + offset))
            path.addLine(to: CGPoint(x: boardOrigin.x + cellSize * CGFloat(boardSize - 1), y: boardOrigin.y + offset))
            path.move(to: CGPoint(x: boardOrigin.x + offset, y: boardOrigin.y))
            path.addLine(to: CGPoint(x: boardOrigin.x + offset, y: boardOrigin.y + cellSize * CGFloat(boardSize - 1)))
        }
        lines.path = path
        lines.strokeColor = SKColor(red: 0.30, green: 0.20, blue: 0.10, alpha: 0.9)
        lines.lineWidth = 1
        gameLayer.addChild(lines)

        // 星位
        for (x, y) in [(3, 3), (3, 9), (9, 3), (9, 9), (6, 6)] {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = SKColor(red: 0.30, green: 0.20, blue: 0.10, alpha: 1)
            dot.strokeColor = .clear
            dot.position = point(x: x, y: y)
            gameLayer.addChild(dot)
        }

        statusLabel = ArcadeFX.label("你的回合（黑棋）", size: 16, color: .white, font: "AvenirNext-Bold")
        statusLabel.position = CGPoint(x: size.width / 2, y: playBottom + 18)
        statusLabel.zPosition = 100
        gameLayer.addChild(statusLabel)
    }

    private func point(x: Int, y: Int) -> CGPoint {
        CGPoint(x: boardOrigin.x + CGFloat(x) * cellSize, y: boardOrigin.y + CGFloat(y) * cellSize)
    }

    private func placeStone(x: Int, y: Int, player: Int) {
        board[y][x] = player
        moveCount += 1

        let stone = SKShapeNode(circleOfRadius: cellSize * 0.42)
        stone.fillColor = player == 1 ? SKColor(white: 0.08, alpha: 1) : SKColor(white: 0.96, alpha: 1)
        stone.strokeColor = player == 1 ? SKColor(white: 0.35, alpha: 1) : SKColor(white: 0.7, alpha: 1)
        stone.lineWidth = 1
        stone.position = point(x: x, y: y)
        stone.zPosition = 10
        stone.setScale(0.3)
        gameLayer.addChild(stone)
        stone.run(.scale(to: 1, duration: 0.12))
        stoneNodes.append(stone)

        lastMoveMarker?.removeFromParent()
        let marker = SKShapeNode(circleOfRadius: cellSize * 0.14)
        marker.fillColor = .systemRed
        marker.strokeColor = .clear
        marker.position = point(x: x, y: y)
        marker.zPosition = 11
        gameLayer.addChild(marker)
        lastMoveMarker = marker

        ArcadeFX.Haptic.light()
    }

    // MARK: - Touch

    override func gameTouchEnded(at location: CGPoint) {
        guard playerTurn, thinking == false else { return }
        let x = Int(round((location.x - boardOrigin.x) / cellSize))
        let y = Int(round((location.y - boardOrigin.y) / cellSize))
        guard x >= 0, x < boardSize, y >= 0, y < boardSize, board[y][x] == 0 else { return }

        placeStone(x: x, y: y, player: 1)
        if checkWin(x: x, y: y, player: 1) {
            wins += 1
            level = wins + 1
            let bonus = max(300 - moveCount * 5, 50)
            addScore(bonus + 100)
            statusLabel.text = "你贏了！"
            ArcadeFX.burst(in: gameLayer, at: point(x: x, y: y), color: .systemYellow, count: 30)
            endGame(message: "勝利！🎉")
            return
        }
        if moveCount >= boardSize * boardSize {
            addScore(50)
            endGame(message: "平手")
            return
        }

        playerTurn = false
        thinking = true
        statusLabel.text = "AI 思考中…"
        // AI 延遲落子，比較有「對弈感」
        run(.sequence([.wait(forDuration: 0.45), .run { [weak self] in self?.aiMove() }]))
    }

    // MARK: - AI

    private func aiMove() {
        guard phase == .playing else { return }
        var bestScore = -1
        var bestMove: (Int, Int) = (boardSize / 2, boardSize / 2)

        for y in 0..<boardSize {
            for x in 0..<boardSize where board[y][x] == 0 {
                guard hasNeighbor(x: x, y: y) else { continue }
                // 進攻 + 防守加權
                let attack = evaluate(x: x, y: y, player: 2)
                let defend = evaluate(x: x, y: y, player: 1)
                let total = attack * 11 / 10 + defend
                if total > bestScore {
                    bestScore = total
                    bestMove = (x, y)
                }
            }
        }
        if board[bestMove.1][bestMove.0] != 0 {
            // 開局或無鄰點時下中央附近
            outer: for y in 0..<boardSize {
                for x in 0..<boardSize where board[y][x] == 0 {
                    bestMove = (x, y); break outer
                }
            }
        }

        placeStone(x: bestMove.0, y: bestMove.1, player: 2)
        thinking = false

        if checkWin(x: bestMove.0, y: bestMove.1, player: 2) {
            statusLabel.text = "AI 獲勝"
            endGame(message: "AI 獲勝")
            return
        }
        playerTurn = true
        statusLabel.text = "你的回合（黑棋）"
    }

    private func hasNeighbor(x: Int, y: Int) -> Bool {
        for dy in -2...2 {
            for dx in -2...2 where dx != 0 || dy != 0 {
                let nx = x + dx, ny = y + dy
                if nx >= 0, nx < boardSize, ny >= 0, ny < boardSize, board[ny][nx] != 0 { return true }
            }
        }
        return false
    }

    /// 評估在 (x, y) 落子後該玩家四個方向的連線強度。
    private func evaluate(x: Int, y: Int, player: Int) -> Int {
        var total = 0
        let directions = [(1, 0), (0, 1), (1, 1), (1, -1)]
        for (dx, dy) in directions {
            var count = 1
            var openEnds = 0
            // 正向
            var step = 1
            while true {
                let nx = x + dx * step, ny = y + dy * step
                guard nx >= 0, nx < boardSize, ny >= 0, ny < boardSize else { break }
                if board[ny][nx] == player { count += 1; step += 1 } else {
                    if board[ny][nx] == 0 { openEnds += 1 }
                    break
                }
            }
            // 反向
            step = 1
            while true {
                let nx = x - dx * step, ny = y - dy * step
                guard nx >= 0, nx < boardSize, ny >= 0, ny < boardSize else { break }
                if board[ny][nx] == player { count += 1; step += 1 } else {
                    if board[ny][nx] == 0 { openEnds += 1 }
                    break
                }
            }
            switch (count, openEnds) {
            case (5..., _): total += 100000
            case (4, 2): total += 12000
            case (4, 1): total += 4000
            case (3, 2): total += 1500
            case (3, 1): total += 300
            case (2, 2): total += 120
            case (2, 1): total += 30
            default: total += 5
            }
        }
        return total
    }

    private func checkWin(x: Int, y: Int, player: Int) -> Bool {
        let directions = [(1, 0), (0, 1), (1, 1), (1, -1)]
        for (dx, dy) in directions {
            var count = 1
            for sign in [1, -1] {
                var step = 1
                while true {
                    let nx = x + dx * step * sign, ny = y + dy * step * sign
                    guard nx >= 0, nx < boardSize, ny >= 0, ny < boardSize, board[ny][nx] == player else { break }
                    count += 1
                    step += 1
                }
            }
            if count >= 5 { return true }
        }
        return false
    }
}
