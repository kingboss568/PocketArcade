import SpriteKit

/// 貪吃蛇進化：滑動轉向、紅/金/藍三種食物、漸層蛇身、速度進化。
final class SnakeEVOScene: BaseArcadeScene {

    private struct Cell: Equatable { var x: Int; var y: Int }
    private enum Dir { case up, down, left, right
        var vector: (Int, Int) {
            switch self {
            case .up: return (0, 1)
            case .down: return (0, -1)
            case .left: return (-1, 0)
            case .right: return (1, 0)
            }
        }
        var opposite: Dir {
            switch self {
            case .up: return .down
            case .down: return .up
            case .left: return .right
            case .right: return .left
            }
        }
    }

    private enum FoodKind { case red, gold, blue }

    private let columns = 17
    private var rows = 0
    private var cellSize: CGFloat = 0
    private var originX: CGFloat = 0
    private var originY: CGFloat = 0

    private var snake: [Cell] = []
    private var segmentNodes: [SKShapeNode] = []
    private var direction: Dir = .up
    private var pendingDirection: Dir = .up
    private var stepInterval: TimeInterval = 0.16
    private var stepAccumulator: TimeInterval = 0
    private var speedBoostUntil: TimeInterval = 0

    private var food: (cell: Cell, kind: FoodKind, node: SKNode)?
    private var swipeStart: CGPoint?
    private var eatenCount = 0

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.04, green: 0.13, blue: 0.07, alpha: 1),
                                    bottom: UIColor(red: 0.02, green: 0.05, blue: 0.03, alpha: 1))
    }

    override func setupGame() {
        cellSize = (size.width - 24) / CGFloat(columns)
        rows = Int((playTop - playBottom - 10) / cellSize)
        originX = 12 + cellSize / 2
        originY = playBottom + 5 + cellSize / 2

        // 棋盤格背景
        let board = SKNode()
        for x in 0..<columns {
            for y in 0..<rows where (x + y) % 2 == 0 {
                let tile = SKSpriteNode(color: SKColor.white.withAlphaComponent(0.030), size: CGSize(width: cellSize, height: cellSize))
                tile.position = point(for: Cell(x: x, y: y))
                board.addChild(tile)
            }
        }
        let border = SKShapeNode(rect: CGRect(x: 12, y: playBottom + 5, width: cellSize * CGFloat(columns), height: cellSize * CGFloat(rows)), cornerRadius: 6)
        border.strokeColor = accent.withAlphaComponent(0.5)
        border.lineWidth = 1.5
        border.glowWidth = 2
        board.addChild(border)
        gameLayer.addChild(board)

        let midX = columns / 2
        let midY = rows / 2
        snake = [Cell(x: midX, y: midY), Cell(x: midX, y: midY - 1), Cell(x: midX, y: midY - 2)]
        rebuildSnakeNodes()
        spawnFood()
    }

    private func point(for cell: Cell) -> CGPoint {
        CGPoint(x: originX + CGFloat(cell.x) * cellSize, y: originY + CGFloat(cell.y) * cellSize)
    }

    private func rebuildSnakeNodes() {
        segmentNodes.forEach { $0.removeFromParent() }
        segmentNodes.removeAll()
        for (index, cell) in snake.enumerated() {
            let node = makeSegment(index: index)
            node.position = point(for: cell)
            gameLayer.addChild(node)
            segmentNodes.append(node)
        }
    }

    private func makeSegment(index: Int) -> SKShapeNode {
        let isHead = index == 0
        let node = SKShapeNode(rectOf: CGSize(width: cellSize - 2, height: cellSize - 2), cornerRadius: (cellSize - 2) * (isHead ? 0.5 : 0.32))
        let progress = CGFloat(index) / CGFloat(max(snake.count - 1, 1))
        node.fillColor = SKColor(
            red: 0.18 + 0.1 * progress,
            green: 0.95 - 0.45 * progress,
            blue: 0.40 - 0.1 * progress,
            alpha: 1
        )
        node.strokeColor = isHead ? .white : .clear
        node.lineWidth = isHead ? 1.6 : 0
        if isHead { node.glowWidth = 3 }
        node.zPosition = isHead ? 6 : 5
        return node
    }

    private func spawnFood() {
        food?.node.removeFromParent()
        var cell: Cell
        repeat {
            cell = Cell(x: Int.random(in: 0..<columns), y: Int.random(in: 0..<rows))
        } while snake.contains(cell)

        let roll = Int.random(in: 0..<10)
        let kind: FoodKind = roll < 6 ? .red : (roll < 8 ? .gold : .blue)
        let color: SKColor
        switch kind {
        case .red: color = SKColor(red: 1, green: 0.32, blue: 0.36, alpha: 1)
        case .gold: color = SKColor(red: 1, green: 0.84, blue: 0.25, alpha: 1)
        case .blue: color = SKColor(red: 0.35, green: 0.65, blue: 1, alpha: 1)
        }
        let node = ArcadeFX.glowDot(radius: cellSize * 0.34, color: color)
        node.position = point(for: cell)
        node.run(.repeatForever(.sequence([.scale(to: 1.18, duration: 0.5), .scale(to: 0.92, duration: 0.5)])))
        gameLayer.addChild(node)
        food = (cell, kind, node)
    }

    // MARK: - Touch（滑動轉向）

    override func gameTouchBegan(at point: CGPoint) { swipeStart = point }

    override func gameTouchMoved(to point: CGPoint, previous: CGPoint) {
        guard let start = swipeStart else { return }
        let dx = point.x - start.x
        let dy = point.y - start.y
        guard max(abs(dx), abs(dy)) > 24 else { return }
        let proposed: Dir = abs(dx) > abs(dy) ? (dx > 0 ? .right : .left) : (dy > 0 ? .up : .down)
        if proposed != direction.opposite { pendingDirection = proposed }
        swipeStart = nil
    }

    override func gameTouchEnded(at point: CGPoint) { swipeStart = nil }

    // MARK: - Update

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        stepAccumulator += deltaTime
        var interval = stepInterval
        if currentTime < speedBoostUntil { interval *= 0.6 }
        guard stepAccumulator >= interval else { return }
        stepAccumulator = 0
        step(currentTime: currentTime)
    }

    private func step(currentTime: TimeInterval) {
        direction = pendingDirection
        let (dx, dy) = direction.vector
        let newHead = Cell(x: snake[0].x + dx, y: snake[0].y + dy)

        // 撞牆或撞自己
        if newHead.x < 0 || newHead.x >= columns || newHead.y < 0 || newHead.y >= rows || snake.dropLast().contains(newHead) {
            ArcadeFX.burst(in: gameLayer, at: point(for: snake[0]), color: .red, count: 22)
            endGame()
            return
        }

        snake.insert(newHead, at: 0)

        var ate = false
        if let current = food, current.cell == newHead {
            ate = true
            eatenCount += 1
            let foodPoint = point(for: newHead)
            switch current.kind {
            case .red:
                addScore(10)
                ArcadeFX.floatingScore("+10", at: foodPoint, in: gameLayer, color: .systemRed, fontSize: 14)
            case .gold:
                addScore(50)
                ArcadeFX.floatingScore("+50", at: foodPoint, in: gameLayer, color: .systemYellow, fontSize: 16)
            case .blue:
                addScore(20)
                speedBoostUntil = currentTime + 3
                flash("加速！", color: .systemBlue, fontSize: 20)
            }
            ArcadeFX.burst(in: gameLayer, at: foodPoint, color: .white, count: 10, speed: 70)
            ArcadeFX.Haptic.medium()
            if eatenCount % 5 == 0 {
                level += 1
                stepInterval = max(stepInterval * 0.93, 0.085)
                flash("LV \(level) 速度提升", color: accent, fontSize: 20)
            }
            spawnFood()
        }

        if ate == false { snake.removeLast() }
        rebuildSnakeNodes()
    }
}
