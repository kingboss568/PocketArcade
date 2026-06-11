import SpriteKit

/// 黑白棋：8×8、合法步提示、翻面動畫、角落加權 AI。
final class ReversiRoyaleScene: BaseArcadeScene {

    private let boardSize = 8
    private var board: [[Int]] = []   // 0 空、1 玩家(黑)、2 AI(白)
    private var discNodes: [[SKShapeNode?]] = []
    private var hintNodes: [SKNode] = []
    private var cellSize: CGFloat = 0
    private var boardOrigin: CGPoint = .zero
    private var playerTurn = true
    private var statusLabel: SKLabelNode!
    private var countLabel: SKLabelNode!
    private var thinking = false

    private let weights: [[Int]] = [
        [120, -20, 20, 5, 5, 20, -20, 120],
        [-20, -40, -5, -5, -5, -5, -40, -20],
        [20, -5, 15, 3, 3, 15, -5, 20],
        [5, -5, 3, 3, 3, 3, -5, 5],
        [5, -5, 3, 3, 3, 3, -5, 5],
        [20, -5, 15, 3, 3, 15, -5, 20],
        [-20, -40, -5, -5, -5, -5, -40, -20],
        [120, -20, 20, 5, 5, 20, -20, 120]
    ]

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.03, green: 0.14, blue: 0.08, alpha: 1),
                                    bottom: UIColor(red: 0.01, green: 0.06, blue: 0.03, alpha: 1))
    }

    override func setupGame() {
        board = Array(repeating: Array(repeating: 0, count: boardSize), count: boardSize)
        discNodes = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)

        let boardWidth = size.width - 28
        cellSize = boardWidth / CGFloat(boardSize)
        let boardY = (playTop + playBottom) / 2 - boardWidth / 2
        boardOrigin = CGPoint(x: 14, y: boardY)

        let table = ArcadeFX.roundedRect(size: CGSize(width: boardWidth + 10, height: boardWidth + 10), radius: 10,
                                         fill: SKColor(red: 0.06, green: 0.36, blue: 0.18, alpha: 1),
                                         stroke: SKColor(red: 0.30, green: 0.65, blue: 0.40, alpha: 1), lineWidth: 2.5)
        table.position = CGPoint(x: size.width / 2, y: boardY + boardWidth / 2)
        gameLayer.addChild(table)

        let lines = SKShapeNode()
        let path = CGMutablePath()
        for i in 0...boardSize {
            let offset = CGFloat(i) * cellSize
            path.move(to: CGPoint(x: boardOrigin.x, y: boardOrigin.y + offset))
            path.addLine(to: CGPoint(x: boardOrigin.x + boardWidth, y: boardOrigin.y + offset))
            path.move(to: CGPoint(x: boardOrigin.x + offset, y: boardOrigin.y))
            path.addLine(to: CGPoint(x: boardOrigin.x + offset, y: boardOrigin.y + boardWidth))
        }
        lines.path = path
        lines.strokeColor = SKColor.black.withAlphaComponent(0.45)
        lines.lineWidth = 1
        gameLayer.addChild(lines)

        statusLabel = ArcadeFX.label("你的回合（黑棋）", size: 16, color: .white, font: "AvenirNext-Bold")
        statusLabel.position = CGPoint(x: size.width / 2, y: playBottom + 30)
        statusLabel.zPosition = 100
        gameLayer.addChild(statusLabel)

        countLabel = ArcadeFX.label("● 2 ─ 2 ○", size: 14, color: .white.withAlphaComponent(0.75), font: "AvenirNext-DemiBold")
        countLabel.position = CGPoint(x: size.width / 2, y: playBottom + 8)
        countLabel.zPosition = 100
        gameLayer.addChild(countLabel)

        // 初始四子
        setDisc(x: 3, y: 3, player: 2, animated: false)
        setDisc(x: 4, y: 4, player: 2, animated: false)
        setDisc(x: 3, y: 4, player: 1, animated: false)
        setDisc(x: 4, y: 3, player: 1, animated: false)
        showHints()
    }

    private func cellCenter(x: Int, y: Int) -> CGPoint {
        CGPoint(x: boardOrigin.x + cellSize / 2 + CGFloat(x) * cellSize,
                y: boardOrigin.y + cellSize / 2 + CGFloat(y) * cellSize)
    }

    private func setDisc(x: Int, y: Int, player: Int, animated: Bool) {
        board[y][x] = player
        if let existing = discNodes[y][x] {
            // 翻面動畫
            let newColor: SKColor = player == 1 ? SKColor(white: 0.10, alpha: 1) : SKColor(white: 0.95, alpha: 1)
            if animated {
                existing.run(.sequence([
                    .scaleX(to: 0.05, duration: 0.10),
                    .run { existing.fillColor = newColor },
                    .scaleX(to: 1, duration: 0.10)
                ]))
            } else {
                existing.fillColor = newColor
            }
            return
        }
        let disc = SKShapeNode(circleOfRadius: cellSize * 0.40)
        disc.fillColor = player == 1 ? SKColor(white: 0.10, alpha: 1) : SKColor(white: 0.95, alpha: 1)
        disc.strokeColor = SKColor.black.withAlphaComponent(0.5)
        disc.lineWidth = 1
        disc.position = cellCenter(x: x, y: y)
        disc.zPosition = 10
        gameLayer.addChild(disc)
        if animated {
            disc.setScale(0.2)
            disc.run(.scale(to: 1, duration: 0.14))
        }
        discNodes[y][x] = disc
    }

    // MARK: - Rules

    private func flips(x: Int, y: Int, player: Int) -> [(Int, Int)] {
        guard board[y][x] == 0 else { return [] }
        let opponent = player == 1 ? 2 : 1
        var result: [(Int, Int)] = []
        for dy in -1...1 {
            for dx in -1...1 where dx != 0 || dy != 0 {
                var line: [(Int, Int)] = []
                var cx = x + dx, cy = y + dy
                while cx >= 0, cx < boardSize, cy >= 0, cy < boardSize, board[cy][cx] == opponent {
                    line.append((cx, cy))
                    cx += dx; cy += dy
                }
                if line.isEmpty == false, cx >= 0, cx < boardSize, cy >= 0, cy < boardSize, board[cy][cx] == player {
                    result += line
                }
            }
        }
        return result
    }

    private func validMoves(for player: Int) -> [(Int, Int)] {
        var moves: [(Int, Int)] = []
        for y in 0..<boardSize {
            for x in 0..<boardSize where flips(x: x, y: y, player: player).isEmpty == false {
                moves.append((x, y))
            }
        }
        return moves
    }

    private func showHints() {
        hintNodes.forEach { $0.removeFromParent() }
        hintNodes.removeAll()
        guard playerTurn else { return }
        for (x, y) in validMoves(for: 1) {
            let hint = SKShapeNode(circleOfRadius: cellSize * 0.13)
            hint.fillColor = SKColor.systemYellow.withAlphaComponent(0.55)
            hint.strokeColor = .clear
            hint.position = cellCenter(x: x, y: y)
            hint.zPosition = 5
            gameLayer.addChild(hint)
            hintNodes.append(hint)
        }
    }

    private func updateCount() {
        let flat = board.flatMap { $0 }
        let black = flat.filter { $0 == 1 }.count
        let white = flat.filter { $0 == 2 }.count
        countLabel.text = "● \(black) ─ \(white) ○"
        score = black * 10
    }

    // MARK: - Touch

    override func gameTouchEnded(at location: CGPoint) {
        guard playerTurn, thinking == false else { return }
        let x = Int((location.x - boardOrigin.x) / cellSize)
        let y = Int((location.y - boardOrigin.y) / cellSize)
        guard x >= 0, x < boardSize, y >= 0, y < boardSize else { return }
        let flipped = flips(x: x, y: y, player: 1)
        guard flipped.isEmpty == false else { return }

        apply(x: x, y: y, player: 1, flipped: flipped)
        playerTurn = false
        advanceTurn()
    }

    private func apply(x: Int, y: Int, player: Int, flipped: [(Int, Int)]) {
        setDisc(x: x, y: y, player: player, animated: true)
        for (index, cell) in flipped.enumerated() {
            run(.sequence([.wait(forDuration: Double(index) * 0.05), .run { [weak self] in
                self?.setDisc(x: cell.0, y: cell.1, player: player, animated: true)
            }]))
        }
        ArcadeFX.Haptic.medium()
        updateCount()
    }

    private func advanceTurn() {
        showHints()
        let playerMoves = validMoves(for: 1)
        let aiMoves = validMoves(for: 2)

        if playerMoves.isEmpty && aiMoves.isEmpty {
            finishMatch()
            return
        }

        if playerTurn == false {
            if aiMoves.isEmpty {
                playerTurn = true
                statusLabel.text = "AI 無步可下，你的回合"
                showHints()
                return
            }
            thinking = true
            statusLabel.text = "AI 思考中…"
            run(.sequence([.wait(forDuration: 0.6), .run { [weak self] in self?.aiMove() }]))
        } else {
            if playerMoves.isEmpty {
                playerTurn = false
                statusLabel.text = "你無步可下，AI 回合"
                advanceTurn()
                return
            }
            statusLabel.text = "你的回合（黑棋）"
        }
    }

    private func aiMove() {
        guard phase == .playing else { return }
        var best: (x: Int, y: Int, value: Int)?
        for (x, y) in validMoves(for: 2) {
            let flipped = flips(x: x, y: y, player: 2)
            let value = weights[y][x] + flipped.count * 4
            if best == nil || value > best!.value { best = (x, y, value) }
        }
        thinking = false
        guard let move = best else {
            playerTurn = true
            advanceTurn()
            return
        }
        apply(x: move.x, y: move.y, player: 2, flipped: flips(x: move.x, y: move.y, player: 2))
        playerTurn = true
        advanceTurn()
    }

    private func finishMatch() {
        let flat = board.flatMap { $0 }
        let black = flat.filter { $0 == 1 }.count
        let white = flat.filter { $0 == 2 }.count
        score = black * 10 + (black > white ? 200 : 0)
        if black > white {
            ArcadeFX.Haptic.success()
            endGame(message: "你贏了！● \(black) : \(white) ○")
        } else if black < white {
            endGame(message: "AI 獲勝 ○ \(white) : \(black) ●")
        } else {
            endGame(message: "平手 \(black) : \(white)")
        }
    }
}
