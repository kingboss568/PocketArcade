import SpriteKit

/// 掃雷高手：點擊翻開、長按插旗、洪水展開，全翻開即獲勝升級。
final class MineSweeperScene: BaseArcadeScene {

    private struct Tile {
        let cover: SKShapeNode
        let label: SKLabelNode
        var isMine = false
        var isRevealed = false
        var isFlagged = false
        var adjacent = 0
        var flagNode: SKLabelNode?
    }

    private var gridWidth = 9
    private var gridHeight = 11
    private var mineCount = 12
    private var tiles: [[Tile]] = []
    private var cellSize: CGFloat = 0
    private var boardOrigin: CGPoint = .zero
    private var firstTap = true
    private var touchStartTime: TimeInterval = 0
    private var touchStartPoint: CGPoint = .zero
    private var longPressTriggered = false
    private var minesLabel: SKLabelNode!
    private var flagsPlaced = 0

    private let numberColors: [SKColor] = [
        .clear, .systemBlue, .systemGreen, .systemRed, .systemPurple,
        .systemOrange, .systemTeal, .white, .systemGray
    ]

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.10, green: 0.11, blue: 0.16, alpha: 1),
                                    bottom: UIColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 1))
    }

    override func setupGame() {
        minesLabel = ArcadeFX.label("💣 \(mineCount)　🚩 0", size: 16, color: .white.withAlphaComponent(0.85), font: "AvenirNext-Bold")
        minesLabel.position = CGPoint(x: size.width / 2, y: playBottom + 14)
        minesLabel.zPosition = 100
        gameLayer.addChild(minesLabel)
        buildBoard()
    }

    private func buildBoard() {
        tiles.forEach { $0.forEach { tile in tile.cover.parent?.removeFromParent() } }
        gameLayer.children.filter { $0.name == "tile" }.forEach { $0.removeFromParent() }
        tiles.removeAll()
        firstTap = true
        flagsPlaced = 0

        mineCount = 10 + level * 2
        minesLabel.text = "💣 \(mineCount)　🚩 0"

        let margin: CGFloat = 12
        cellSize = min((size.width - margin * 2) / CGFloat(gridWidth),
                       (playTop - playBottom - 50) / CGFloat(gridHeight))
        let boardWidth = cellSize * CGFloat(gridWidth)
        let boardHeight = cellSize * CGFloat(gridHeight)
        boardOrigin = CGPoint(x: (size.width - boardWidth) / 2,
                              y: playBottom + 36 + (playTop - playBottom - 50 - boardHeight) / 2)

        for y in 0..<gridHeight {
            var row: [Tile] = []
            for x in 0..<gridWidth {
                let container = SKNode()
                container.name = "tile"
                container.position = cellCenter(x: x, y: y)
                container.zPosition = 10
                gameLayer.addChild(container)

                let base = ArcadeFX.roundedRect(size: CGSize(width: cellSize - 2, height: cellSize - 2), radius: 4,
                                                fill: SKColor(white: 0.16, alpha: 1))
                container.addChild(base)

                let label = ArcadeFX.label("", size: cellSize * 0.5, color: .white, font: "AvenirNext-Heavy")
                label.zPosition = 1
                container.addChild(label)

                let cover = ArcadeFX.roundedRect(size: CGSize(width: cellSize - 2, height: cellSize - 2), radius: 4,
                                                 fill: (x + y) % 2 == 0
                                                    ? SKColor(red: 0.36, green: 0.42, blue: 0.56, alpha: 1)
                                                    : SKColor(red: 0.31, green: 0.37, blue: 0.50, alpha: 1),
                                                 stroke: .white.withAlphaComponent(0.12), lineWidth: 0.5)
                cover.zPosition = 2
                container.addChild(cover)

                row.append(Tile(cover: cover, label: label))
            }
            tiles.append(row)
        }
    }

    private func cellCenter(x: Int, y: Int) -> CGPoint {
        CGPoint(x: boardOrigin.x + cellSize / 2 + CGFloat(x) * cellSize,
                y: boardOrigin.y + cellSize / 2 + CGFloat(y) * cellSize)
    }

    private func placeMines(avoiding: (Int, Int)) {
        var placed = 0
        while placed < mineCount {
            let x = Int.random(in: 0..<gridWidth)
            let y = Int.random(in: 0..<gridHeight)
            // 避開第一次點擊及其鄰格
            if abs(x - avoiding.0) <= 1 && abs(y - avoiding.1) <= 1 { continue }
            if tiles[y][x].isMine { continue }
            tiles[y][x].isMine = true
            placed += 1
        }
        for y in 0..<gridHeight {
            for x in 0..<gridWidth {
                var count = 0
                forEachNeighbor(x: x, y: y) { nx, ny in if tiles[ny][nx].isMine { count += 1 } }
                tiles[y][x].adjacent = count
            }
        }
    }

    private func forEachNeighbor(x: Int, y: Int, _ body: (Int, Int) -> Void) {
        for dy in -1...1 {
            for dx in -1...1 where dx != 0 || dy != 0 {
                let nx = x + dx, ny = y + dy
                if nx >= 0, nx < gridWidth, ny >= 0, ny < gridHeight { body(nx, ny) }
            }
        }
    }

    // MARK: - Touch（點翻、長按旗）

    override func gameTouchBegan(at point: CGPoint) {
        touchStartTime = CACurrentMediaTime()
        touchStartPoint = point
        longPressTriggered = false
        // 排程長按偵測
        run(.sequence([.wait(forDuration: 0.38), .run { [weak self] in
            guard let self, self.longPressTriggered == false, self.phase == .playing else { return }
            if CACurrentMediaTime() - self.touchStartTime >= 0.36 {
                self.longPressTriggered = true
                self.toggleFlag(at: self.touchStartPoint)
            }
        }]), withKey: "longPress")
    }

    override func gameTouchEnded(at point: CGPoint) {
        removeAction(forKey: "longPress")
        guard longPressTriggered == false else { return }
        guard CACurrentMediaTime() - touchStartTime < 0.36 else { return }
        reveal(at: point)
    }

    private func gridIndex(at point: CGPoint) -> (Int, Int)? {
        let x = Int((point.x - boardOrigin.x) / cellSize)
        let y = Int((point.y - boardOrigin.y) / cellSize)
        guard x >= 0, x < gridWidth, y >= 0, y < gridHeight else { return nil }
        return (x, y)
    }

    private func toggleFlag(at point: CGPoint) {
        guard let (x, y) = gridIndex(at: point), tiles[y][x].isRevealed == false else { return }
        ArcadeFX.Haptic.medium()
        if tiles[y][x].isFlagged {
            tiles[y][x].isFlagged = false
            tiles[y][x].flagNode?.removeFromParent()
            tiles[y][x].flagNode = nil
            flagsPlaced -= 1
        } else {
            let flag = ArcadeFX.emojiNode("🚩", size: cellSize * 0.55)
            flag.position = cellCenter(x: x, y: y)
            flag.zPosition = 20
            flag.setScale(0.3)
            flag.run(.scale(to: 1, duration: 0.12))
            gameLayer.addChild(flag)
            tiles[y][x].isFlagged = true
            tiles[y][x].flagNode = flag
            flagsPlaced += 1
        }
        minesLabel.text = "💣 \(mineCount)　🚩 \(flagsPlaced)"
    }

    private func reveal(at point: CGPoint) {
        guard let (x, y) = gridIndex(at: point) else { return }
        guard tiles[y][x].isRevealed == false, tiles[y][x].isFlagged == false else { return }

        if firstTap {
            firstTap = false
            placeMines(avoiding: (x, y))
        }

        if tiles[y][x].isMine {
            // 踩雷
            revealAllMines()
            ArcadeFX.burst(in: gameLayer, at: cellCenter(x: x, y: y), color: .systemRed, count: 30, speed: 180)
            ArcadeFX.Haptic.error()
            endGame(message: "踩到地雷！💥")
            return
        }

        floodReveal(x: x, y: y)
        ArcadeFX.Haptic.light()
        checkWin()
    }

    private func floodReveal(x: Int, y: Int) {
        var stack = [(x, y)]
        var revealed = 0
        while let (cx, cy) = stack.popLast() {
            guard tiles[cy][cx].isRevealed == false, tiles[cy][cx].isFlagged == false, tiles[cy][cx].isMine == false else { continue }
            tiles[cy][cx].isRevealed = true
            revealed += 1
            let tile = tiles[cy][cx]
            tile.cover.run(.fadeOut(withDuration: 0.12))
            if tile.adjacent > 0 {
                tile.label.text = "\(tile.adjacent)"
                tile.label.fontColor = numberColors[min(tile.adjacent, numberColors.count - 1)]
            } else {
                forEachNeighbor(x: cx, y: cy) { nx, ny in
                    if tiles[ny][nx].isRevealed == false { stack.append((nx, ny)) }
                }
            }
        }
        addScore(revealed * 5)
    }

    private func revealAllMines() {
        for y in 0..<gridHeight {
            for x in 0..<gridWidth where tiles[y][x].isMine {
                tiles[y][x].cover.run(.fadeOut(withDuration: 0.3))
                tiles[y][x].label.text = "💣"
            }
        }
    }

    private func checkWin() {
        for row in tiles {
            for tile in row where tile.isMine == false && tile.isRevealed == false { return }
        }
        addScore(200 + mineCount * 10)
        level += 1
        flash("掃雷成功！LV \(level)", color: accent)
        ArcadeFX.Haptic.success()
        run(.sequence([.wait(forDuration: 1.2), .run { [weak self] in self?.buildBoard() }]))
    }
}
