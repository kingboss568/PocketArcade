import SpriteKit

/// 泡泡消消：拖曳瞄準、放開發射，三顆同色消除，懸空泡泡掉落加分。
final class BubblePopScene: BaseArcadeScene {

    private let columns = 10
    private var bubbleRadius: CGFloat = 0
    private var grid: [[SKShapeNode?]] = []   // [row][col]，row 0 在最上面
    private var gridTop: CGFloat = 0
    private var shooter: SKNode!
    private var currentBubble: SKShapeNode?
    private var nextBubble: SKShapeNode?
    private var flying: (node: SKShapeNode, velocity: CGVector)?
    private var aimLine: SKShapeNode!
    private var shotsUntilDrop = 6
    private var palette: [SKColor] {
        [SKColor(red: 1, green: 0.36, blue: 0.42, alpha: 1),
         SKColor(red: 1, green: 0.80, blue: 0.28, alpha: 1),
         SKColor(red: 0.34, green: 0.86, blue: 0.50, alpha: 1),
         SKColor(red: 0.36, green: 0.66, blue: 1, alpha: 1),
         SKColor(red: 0.80, green: 0.48, blue: 1, alpha: 1)]
    }
    private var activeColorCount: Int { min(3 + level / 2, palette.count) }
    private var deadlineY: CGFloat = 0

    override func setupGame() {
        bubbleRadius = size.width / CGFloat(columns) / 2
        gridTop = playTop - bubbleRadius
        deadlineY = playBottom + 130

        // 底線
        let line = SKShapeNode(rect: CGRect(x: 0, y: deadlineY, width: size.width, height: 1))
        line.strokeColor = SKColor.red.withAlphaComponent(0.55)
        line.lineWidth = 1.5
        gameLayer.addChild(line)

        // 發射台
        shooter = SKNode()
        shooter.position = CGPoint(x: size.width / 2, y: playBottom + 56)
        let base = SKShapeNode(circleOfRadius: bubbleRadius + 7)
        base.strokeColor = accent.withAlphaComponent(0.8)
        base.lineWidth = 2
        base.glowWidth = 3
        shooter.addChild(base)
        gameLayer.addChild(shooter)

        aimLine = SKShapeNode()
        aimLine.strokeColor = .white.withAlphaComponent(0.45)
        aimLine.lineWidth = 2
        aimLine.zPosition = 5
        gameLayer.addChild(aimLine)

        buildGrid(rows: 5)
        loadShooter()
    }

    // MARK: - Grid helpers

    private func cellCount(forRow row: Int) -> Int { row % 2 == 0 ? columns : columns - 1 }

    private func position(row: Int, col: Int) -> CGPoint {
        let offset: CGFloat = row % 2 == 0 ? 0 : bubbleRadius
        return CGPoint(x: bubbleRadius + offset + CGFloat(col) * bubbleRadius * 2,
                       y: gridTop - CGFloat(row) * bubbleRadius * 1.74)
    }

    private func makeBubble(color: SKColor) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: bubbleRadius - 1.5)
        node.fillColor = color
        node.strokeColor = .white.withAlphaComponent(0.55)
        node.lineWidth = 1.2
        let shine = SKShapeNode(circleOfRadius: bubbleRadius * 0.28)
        shine.fillColor = .white.withAlphaComponent(0.35)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -bubbleRadius * 0.3, y: bubbleRadius * 0.3)
        node.addChild(shine)
        node.userData = ["color": color]
        return node
    }

    private func buildGrid(rows: Int) {
        grid = []
        for row in 0..<rows {
            var line: [SKShapeNode?] = []
            for col in 0..<cellCount(forRow: row) {
                let color = palette[Int.random(in: 0..<activeColorCount)]
                let bubble = makeBubble(color: color)
                bubble.position = position(row: row, col: col)
                gameLayer.addChild(bubble)
                line.append(bubble)
            }
            grid.append(line)
        }
    }

    private func loadShooter() {
        let color = palette[Int.random(in: 0..<activeColorCount)]
        if let next = nextBubble {
            currentBubble = next
            next.run(.move(to: shooter.position, duration: 0.15))
        } else {
            currentBubble = makeBubble(color: color)
            currentBubble!.position = shooter.position
            gameLayer.addChild(currentBubble!)
        }
        let nextColor = palette[Int.random(in: 0..<activeColorCount)]
        let next = makeBubble(color: nextColor)
        next.position = CGPoint(x: shooter.position.x + 70, y: shooter.position.y - 8)
        next.setScale(0.6)
        gameLayer.addChild(next)
        nextBubble = next
    }

    // MARK: - Touch（瞄準與發射）

    override func gameTouchBegan(at point: CGPoint) { updateAim(to: point) }
    override func gameTouchMoved(to point: CGPoint, previous: CGPoint) { updateAim(to: point) }

    override func gameTouchEnded(at point: CGPoint) {
        aimLine.path = nil
        guard flying == nil, let bubble = currentBubble else { return }
        let dx = point.x - shooter.position.x
        let dy = point.y - shooter.position.y
        guard dy > 30 else { return }
        let length = hypot(dx, dy)
        let speed: CGFloat = 720
        flying = (bubble, CGVector(dx: dx / length * speed, dy: dy / length * speed))
        currentBubble = nil
        ArcadeFX.Haptic.light()
    }

    private func updateAim(to point: CGPoint) {
        guard point.y > shooter.position.y + 30 else { aimLine.path = nil; return }
        let path = CGMutablePath()
        path.move(to: shooter.position)
        path.addLine(to: point)
        aimLine.path = path
    }

    // MARK: - Update

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        guard var shot = flying else { return }
        let dt = CGFloat(deltaTime)
        var pos = shot.node.position
        pos.x += shot.velocity.dx * dt
        pos.y += shot.velocity.dy * dt

        if pos.x < bubbleRadius { pos.x = bubbleRadius; shot.velocity.dx = abs(shot.velocity.dx) }
        if pos.x > size.width - bubbleRadius { pos.x = size.width - bubbleRadius; shot.velocity.dx = -abs(shot.velocity.dx) }

        shot.node.position = pos
        flying = shot

        // 撞頂或撞到泡泡 → 吸附
        if pos.y >= gridTop - 2 {
            snap(shot.node)
            return
        }
        for (row, line) in grid.enumerated() {
            for case let bubble? in line {
                let distance = hypot(bubble.position.x - pos.x, bubble.position.y - pos.y)
                if distance < bubbleRadius * 1.82 {
                    _ = row
                    snap(shot.node)
                    return
                }
            }
        }
        if pos.y < playBottom { shot.node.removeFromParent(); flying = nil; loadShooter() }
    }

    private func snap(_ node: SKShapeNode) {
        flying = nil
        // 找最近空格
        var best: (row: Int, col: Int, distance: CGFloat)?
        var rowIndex = 0
        while rowIndex < grid.count + 1 {
            if rowIndex == grid.count { grid.append(Array(repeating: nil, count: cellCount(forRow: rowIndex))) }
            for col in 0..<cellCount(forRow: rowIndex) where grid[rowIndex][col] == nil {
                let p = position(row: rowIndex, col: col)
                let d = hypot(p.x - node.position.x, p.y - node.position.y)
                if best == nil || d < best!.distance { best = (rowIndex, col, d) }
            }
            if let candidate = best, candidate.distance < bubbleRadius * 2.2 { break }
            rowIndex += 1
            if rowIndex > 14 { break }
        }
        guard let target = best else { node.removeFromParent(); loadShooter(); return }
        grid[target.row][target.col] = node
        node.run(.move(to: position(row: target.row, col: target.col), duration: 0.08))
        ArcadeFX.Haptic.medium()

        let color = node.userData?["color"] as? SKColor ?? .white
        let cluster = floodFill(from: (target.row, target.col)) { bubble in
            (bubble.userData?["color"] as? SKColor) == color
        }

        if cluster.count >= 3 {
            for (r, c) in cluster {
                if let bubble = grid[r][c] {
                    ArcadeFX.burst(in: gameLayer, at: bubble.position, color: color, count: 8, speed: 80)
                    bubble.removeFromParent()
                    grid[r][c] = nil
                }
            }
            addScore(cluster.count * 10)
            dropFloating()
            ArcadeFX.Haptic.success()
        }

        shotsUntilDrop -= 1
        if shotsUntilDrop <= 0 {
            shotsUntilDrop = 6
            pushDown()
        }
        checkState()
        loadShooter()
    }

    private func neighbors(of cell: (Int, Int)) -> [(Int, Int)] {
        let (row, col) = cell
        let even = row % 2 == 0
        let candidates = [
            (row, col - 1), (row, col + 1),
            (row - 1, even ? col - 1 : col), (row - 1, even ? col : col + 1),
            (row + 1, even ? col - 1 : col), (row + 1, even ? col : col + 1)
        ]
        return candidates.filter { $0.0 >= 0 && $0.0 < grid.count && $0.1 >= 0 && $0.1 < cellCount(forRow: $0.0) }
    }

    private func floodFill(from start: (Int, Int), matching: (SKShapeNode) -> Bool) -> [(Int, Int)] {
        guard grid[start.0][start.1] != nil else { return [] }
        var visited = Set<Int>()
        var stack = [start]
        var result: [(Int, Int)] = []
        func key(_ c: (Int, Int)) -> Int { c.0 * 100 + c.1 }
        visited.insert(key(start))
        while let cell = stack.popLast() {
            guard let bubble = grid[cell.0][cell.1], matching(bubble) else { continue }
            result.append(cell)
            for next in neighbors(of: cell) where visited.contains(key(next)) == false {
                visited.insert(key(next))
                if grid[next.0][next.1] != nil { stack.append(next) }
            }
        }
        return result
    }

    private func dropFloating() {
        // 從第 0 列出發可達的都安全，其餘掉落
        var anchored = Set<Int>()
        func key(_ c: (Int, Int)) -> Int { c.0 * 100 + c.1 }
        var stack: [(Int, Int)] = []
        if grid.isEmpty == false {
            for col in 0..<cellCount(forRow: 0) where grid[0][col] != nil {
                stack.append((0, col))
                anchored.insert(key((0, col)))
            }
        }
        while let cell = stack.popLast() {
            for next in neighbors(of: cell) where anchored.contains(key(next)) == false {
                if grid[next.0][next.1] != nil {
                    anchored.insert(key(next))
                    stack.append(next)
                }
            }
        }
        var dropped = 0
        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                if let bubble = grid[row][col], anchored.contains(key((row, col))) == false {
                    dropped += 1
                    grid[row][col] = nil
                    bubble.run(.sequence([
                        .group([.moveBy(x: CGFloat.random(in: -30...30), y: -400, duration: 0.6), .fadeOut(withDuration: 0.6)]),
                        .removeFromParent()
                    ]))
                }
            }
        }
        if dropped > 0 {
            addScore(dropped * 20)
            ArcadeFX.floatingScore("+\(dropped * 20)", at: CGPoint(x: size.width / 2, y: size.height / 2), in: gameLayer, color: .systemYellow)
        }
    }

    private func pushDown() {
        gridTop -= bubbleRadius * 1.74
        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                grid[row][col]?.run(.move(to: position(row: row, col: col), duration: 0.22))
            }
        }
        // 新的一列補在最上面（重建索引太複雜，改用整體下移；頂端不補泡泡保持簡潔）
        flash("泡泡下壓！", color: .systemOrange, fontSize: 20)
    }

    private func checkState() {
        var remaining = 0
        var lowest: CGFloat = .greatestFiniteMagnitude
        for row in 0..<grid.count {
            for col in 0..<grid[row].count where grid[row][col] != nil {
                remaining += 1
                lowest = min(lowest, position(row: row, col: col).y)
            }
        }
        if remaining == 0 {
            level += 1
            addScore(200)
            flash("全部清光！LV \(level)", color: accent)
            ArcadeFX.Haptic.success()
            gridTop = playTop - bubbleRadius
            shotsUntilDrop = 6
            buildGrid(rows: min(4 + level, 8))
        } else if lowest - bubbleRadius < deadlineY {
            endGame(message: "泡泡到底了！")
        }
    }
}
