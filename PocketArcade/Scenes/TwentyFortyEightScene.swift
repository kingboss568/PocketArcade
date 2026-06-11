import SpriteKit

/// 2048：滑動合併、彈跳動畫、合出 2048 獲勝可續玩。
final class TwentyFortyEightScene: BaseArcadeScene {

    private let gridSize = 4
    private var board: [[Int]] = []
    private var tileNodes: [[SKNode?]] = []
    private var boardOrigin: CGPoint = .zero
    private var cellSize: CGFloat = 0
    private let spacing: CGFloat = 10
    private var swipeStart: CGPoint?
    private var animating = false
    private var hasWon = false

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.16, green: 0.13, blue: 0.08, alpha: 1),
                                    bottom: UIColor(red: 0.07, green: 0.05, blue: 0.03, alpha: 1))
    }

    override func setupGame() {
        let boardWidth = size.width - 32
        cellSize = (boardWidth - spacing * CGFloat(gridSize + 1)) / CGFloat(gridSize)
        let boardY = (playTop + playBottom) / 2 - boardWidth / 2
        boardOrigin = CGPoint(x: 16, y: boardY)

        let frame = ArcadeFX.roundedRect(size: CGSize(width: boardWidth, height: boardWidth), radius: 14,
                                         fill: SKColor.white.withAlphaComponent(0.07),
                                         stroke: accent.withAlphaComponent(0.5), lineWidth: 1.5)
        frame.position = CGPoint(x: size.width / 2, y: boardY + boardWidth / 2)
        gameLayer.addChild(frame)

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let slot = ArcadeFX.roundedRect(size: CGSize(width: cellSize, height: cellSize), radius: 8,
                                                fill: SKColor.white.withAlphaComponent(0.05))
                slot.position = cellCenter(row: row, col: col)
                gameLayer.addChild(slot)
            }
        }

        board = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        tileNodes = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)
        spawnTile()
        spawnTile()
    }

    private func cellCenter(row: Int, col: Int) -> CGPoint {
        CGPoint(x: boardOrigin.x + spacing + cellSize / 2 + CGFloat(col) * (cellSize + spacing),
                y: boardOrigin.y + spacing + cellSize / 2 + CGFloat(gridSize - 1 - row) * (cellSize + spacing))
    }

    private func tileColor(_ value: Int) -> SKColor {
        switch value {
        case 2: return SKColor(red: 0.93, green: 0.89, blue: 0.85, alpha: 1)
        case 4: return SKColor(red: 0.93, green: 0.88, blue: 0.78, alpha: 1)
        case 8: return SKColor(red: 0.95, green: 0.69, blue: 0.47, alpha: 1)
        case 16: return SKColor(red: 0.96, green: 0.58, blue: 0.39, alpha: 1)
        case 32: return SKColor(red: 0.96, green: 0.49, blue: 0.37, alpha: 1)
        case 64: return SKColor(red: 0.96, green: 0.37, blue: 0.23, alpha: 1)
        case 128: return SKColor(red: 0.93, green: 0.81, blue: 0.45, alpha: 1)
        case 256: return SKColor(red: 0.93, green: 0.80, blue: 0.38, alpha: 1)
        case 512: return SKColor(red: 0.93, green: 0.78, blue: 0.31, alpha: 1)
        case 1024: return SKColor(red: 0.93, green: 0.77, blue: 0.25, alpha: 1)
        case 2048: return SKColor(red: 0.93, green: 0.76, blue: 0.18, alpha: 1)
        default: return SKColor(red: 0.24, green: 0.22, blue: 0.20, alpha: 1)
        }
    }

    private func makeTileNode(value: Int, row: Int, col: Int) -> SKNode {
        let container = SKNode()
        let bg = ArcadeFX.roundedRect(size: CGSize(width: cellSize, height: cellSize), radius: 8, fill: tileColor(value))
        if value >= 128 {
            bg.glowWidth = 3
            bg.strokeColor = tileColor(value).withAlphaComponent(0.8)
        }
        container.addChild(bg)
        let fontSize: CGFloat = value < 100 ? cellSize * 0.45 : (value < 1000 ? cellSize * 0.36 : cellSize * 0.3)
        let isLight = value <= 4
        let label = ArcadeFX.label("\(value)", size: fontSize, color: isLight ? SKColor(white: 0.25, alpha: 1) : .white, font: "AvenirNext-Heavy")
        container.addChild(label)
        container.position = cellCenter(row: row, col: col)
        container.zPosition = 10
        return container
    }

    private func spawnTile() {
        var empty: [(Int, Int)] = []
        for row in 0..<gridSize { for col in 0..<gridSize where board[row][col] == 0 { empty.append((row, col)) } }
        guard let (row, col) = empty.randomElement() else { return }
        let value = Int.random(in: 0..<10) == 0 ? 4 : 2
        board[row][col] = value
        let node = makeTileNode(value: value, row: row, col: col)
        node.setScale(0.2)
        gameLayer.addChild(node)
        node.run(.scale(to: 1, duration: 0.14))
        tileNodes[row][col] = node
    }

    // MARK: - Touch

    override func gameTouchBegan(at point: CGPoint) { swipeStart = point }

    override func gameTouchEnded(at point: CGPoint) {
        guard let start = swipeStart, animating == false else { swipeStart = nil; return }
        swipeStart = nil
        let dx = point.x - start.x
        let dy = point.y - start.y
        guard max(abs(dx), abs(dy)) > 28 else { return }
        let direction: (Int, Int) = abs(dx) > abs(dy) ? (0, dx > 0 ? 1 : -1) : (dy > 0 ? -1 : 1, 0)
        move(dRow: direction.0, dCol: direction.1)
    }

    // MARK: - Move logic

    private func move(dRow: Int, dCol: Int) {
        var moved = false
        var gained = 0
        var merged = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        var animations: [(node: SKNode, to: CGPoint, mergeInto: Int?, row: Int, col: Int)] = []

        let rowOrder = dRow > 0 ? Array((0..<gridSize).reversed()) : Array(0..<gridSize)
        let colOrder = dCol > 0 ? Array((0..<gridSize).reversed()) : Array(0..<gridSize)

        for row in rowOrder {
            for col in colOrder where board[row][col] != 0 {
                let value = board[row][col]
                var targetRow = row
                var targetCol = col
                while true {
                    let nextRow = targetRow + dRow
                    let nextCol = targetCol + dCol
                    guard nextRow >= 0, nextRow < gridSize, nextCol >= 0, nextCol < gridSize else { break }
                    if board[nextRow][nextCol] == 0 {
                        targetRow = nextRow; targetCol = nextCol
                    } else if board[nextRow][nextCol] == value && merged[nextRow][nextCol] == false {
                        targetRow = nextRow; targetCol = nextCol
                        break
                    } else { break }
                }
                guard targetRow != row || targetCol != col else { continue }
                moved = true
                let node = tileNodes[row][col]!
                tileNodes[row][col] = nil
                if board[targetRow][targetCol] == value {
                    // 合併
                    let newValue = value * 2
                    board[targetRow][targetCol] = newValue
                    board[row][col] = 0
                    merged[targetRow][targetCol] = true
                    gained += newValue
                    animations.append((node, cellCenter(row: targetRow, col: targetCol), newValue, targetRow, targetCol))
                } else {
                    board[targetRow][targetCol] = value
                    board[row][col] = 0
                    tileNodes[targetRow][targetCol] = node
                    animations.append((node, cellCenter(row: targetRow, col: targetCol), nil, targetRow, targetCol))
                }
            }
        }

        guard moved else { return }
        animating = true
        ArcadeFX.Haptic.light()

        let group = DispatchGroup()
        for animation in animations {
            group.enter()
            let slide = SKAction.move(to: animation.to, duration: 0.10)
            slide.timingMode = .easeOut
            animation.node.run(slide) {
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            // 處理合併節點重建
            for animation in animations {
                if let newValue = animation.mergeInto {
                    // 移除舊節點（被合併的與目標）
                    animation.node.removeFromParent()
                    self.tileNodes[animation.row][animation.col]?.removeFromParent()
                    let node = self.makeTileNode(value: newValue, row: animation.row, col: animation.col)
                    node.setScale(1.0)
                    self.gameLayer.addChild(node)
                    node.run(.sequence([.scale(to: 1.18, duration: 0.07), .scale(to: 1, duration: 0.08)]))
                    self.tileNodes[animation.row][animation.col] = node
                    if newValue == 2048 && self.hasWon == false {
                        self.hasWon = true
                        self.flash("🎉 2048 達成！", color: .systemYellow)
                        ArcadeFX.Haptic.success()
                    }
                }
            }
            if gained > 0 {
                self.addScore(gained)
                self.level = max(self.level, Int(log2(Double(self.maxTile()))) - 6)
            }
            self.spawnTile()
            self.animating = false
            if self.isStuck() { self.endGame(message: "無路可走！") }
        }
    }

    private func maxTile() -> Int {
        board.flatMap { $0 }.max() ?? 2
    }

    private func isStuck() -> Bool {
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if board[row][col] == 0 { return false }
                if col + 1 < gridSize && board[row][col] == board[row][col + 1] { return false }
                if row + 1 < gridSize && board[row][col] == board[row + 1][col] { return false }
            }
        }
        return true
    }
}
