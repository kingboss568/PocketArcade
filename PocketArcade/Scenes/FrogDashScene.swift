import SpriteKit

/// 青蛙跳跳：點擊前跳、滑動左右移，穿越車道與河流抵達終點。
final class FrogDashScene: BaseArcadeScene {

    private enum RowKind { case grass, road, river, goal }

    private struct Lane {
        let kind: RowKind
        let y: CGFloat
        var speed: CGFloat
        var nodes: [SKNode]
    }

    private var lanes: [Lane] = []
    private var frog: SKLabelNode!
    private var frogRow = 0
    private var frogColumn = 4
    private var lives = 3
    private var livesLabel: SKLabelNode!
    private var rowHeight: CGFloat = 0
    private var columnWidth: CGFloat = 0
    private let columns = 9
    private var rowCount = 0
    private var swipeStart: CGPoint?
    private var onLog: SKNode?
    private var hopping = false

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.05, green: 0.10, blue: 0.18, alpha: 1),
                                    bottom: UIColor(red: 0.03, green: 0.06, blue: 0.05, alpha: 1))
    }

    override func setupGame() {
        columnWidth = size.width / CGFloat(columns)
        rowCount = 12
        rowHeight = (playTop - playBottom - 8) / CGFloat(rowCount)
        buildLevel()

        frog = ArcadeFX.emojiNode("🐸", size: rowHeight * 0.72)
        frog.zPosition = 50
        gameLayer.addChild(frog)
        placeFrogAtStart()

        livesLabel = ArcadeFX.label("♥♥♥", size: 15, color: .systemRed, font: "AvenirNext-Bold")
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.position = CGPoint(x: 14, y: playBottom - 6)
        livesLabel.zPosition = 100
        gameLayer.addChild(livesLabel)
    }

    private func rowY(_ row: Int) -> CGFloat { playBottom + 8 + rowHeight * (CGFloat(row) + 0.5) }

    private func buildLevel() {
        lanes.forEach { $0.nodes.forEach { $0.removeFromParent() } }
        gameLayer.children.filter { $0.name == "laneBG" }.forEach { $0.removeFromParent() }
        lanes.removeAll()

        let speedScale: CGFloat = 1 + CGFloat(level - 1) * 0.14
        for row in 0..<rowCount {
            let kind: RowKind
            switch row {
            case 0, 6: kind = .grass
            case 1...5: kind = row % 2 == 1 ? .road : (row == 4 ? .road : .road)
            case rowCount - 1: kind = .goal
            default: kind = .river
            }

            let bgColor: SKColor
            switch kind {
            case .grass: bgColor = SKColor(red: 0.10, green: 0.28, blue: 0.12, alpha: 1)
            case .road: bgColor = SKColor(red: 0.13, green: 0.13, blue: 0.16, alpha: 1)
            case .river: bgColor = SKColor(red: 0.07, green: 0.16, blue: 0.34, alpha: 1)
            case .goal: bgColor = SKColor(red: 0.16, green: 0.34, blue: 0.14, alpha: 1)
            }
            let bg = SKSpriteNode(color: bgColor, size: CGSize(width: size.width, height: rowHeight))
            bg.position = CGPoint(x: size.width / 2, y: rowY(row))
            bg.zPosition = 1
            bg.name = "laneBG"
            gameLayer.addChild(bg)

            var lane = Lane(kind: kind, y: rowY(row), speed: 0, nodes: [])
            if kind == .road {
                lane.speed = (row % 2 == 0 ? 1 : -1) * CGFloat.random(in: 70...130) * speedScale
                let emojis = ["🚗", "🚕", "🚙", "🚓", "🚌"]
                let count = Int.random(in: 2...3)
                for i in 0..<count {
                    let car = ArcadeFX.emojiNode(emojis.randomElement()!, size: rowHeight * 0.78)
                    car.xScale = lane.speed > 0 ? -1 : 1
                    car.position = CGPoint(x: CGFloat(i) * size.width / CGFloat(count), y: lane.y)
                    car.zPosition = 10
                    gameLayer.addChild(car)
                    lane.nodes.append(car)
                }
            } else if kind == .river {
                lane.speed = (row % 2 == 0 ? 1 : -1) * CGFloat.random(in: 50...95) * speedScale
                let count = 3
                for i in 0..<count {
                    let logWidth = columnWidth * CGFloat.random(in: 2.2...3.2)
                    let log = SKShapeNode(rectOf: CGSize(width: logWidth, height: rowHeight * 0.66), cornerRadius: rowHeight * 0.3)
                    log.fillColor = SKColor(red: 0.45, green: 0.30, blue: 0.16, alpha: 1)
                    log.strokeColor = SKColor(red: 0.60, green: 0.42, blue: 0.24, alpha: 1)
                    log.lineWidth = 2
                    log.position = CGPoint(x: CGFloat(i) * size.width / CGFloat(count), y: lane.y)
                    log.zPosition = 10
                    gameLayer.addChild(log)
                    lane.nodes.append(log)
                }
            } else if kind == .goal {
                let flag = ArcadeFX.emojiNode("🏁", size: rowHeight * 0.8)
                flag.position = CGPoint(x: size.width / 2, y: lane.y)
                flag.zPosition = 10
                gameLayer.addChild(flag)
                lane.nodes.append(flag)
            }
            lanes.append(lane)
        }
    }

    private func placeFrogAtStart() {
        frogRow = 0
        frogColumn = columns / 2
        onLog = nil
        frog.position = CGPoint(x: columnWidth * (CGFloat(frogColumn) + 0.5), y: rowY(0))
    }

    // MARK: - Touch

    override func gameTouchBegan(at point: CGPoint) { swipeStart = point }

    override func gameTouchEnded(at point: CGPoint) {
        guard let start = swipeStart, hopping == false else { swipeStart = nil; return }
        swipeStart = nil
        let dx = point.x - start.x
        let dy = point.y - start.y
        if max(abs(dx), abs(dy)) < 26 {
            hop(dRow: 1, dCol: 0)
        } else if abs(dx) > abs(dy) {
            hop(dRow: 0, dCol: dx > 0 ? 1 : -1)
        } else {
            hop(dRow: dy > 0 ? 1 : -1, dCol: 0)
        }
    }

    private func hop(dRow: Int, dCol: Int) {
        let newRow = frogRow + dRow
        guard newRow >= 0, newRow < rowCount else { return }
        var newX = frog.position.x + CGFloat(dCol) * columnWidth
        newX = min(max(newX, columnWidth / 2), size.width - columnWidth / 2)

        frogRow = newRow
        onLog = nil
        hopping = true
        ArcadeFX.Haptic.light()
        let jump = SKAction.group([
            .move(to: CGPoint(x: newX, y: rowY(newRow)), duration: 0.13),
            .sequence([.scale(to: 1.3, duration: 0.065), .scale(to: 1, duration: 0.065)])
        ])
        frog.run(jump) { [weak self] in
            self?.hopping = false
            self?.checkLanding()
        }
        if dRow > 0 { addScore(2) }
    }

    // MARK: - Update

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        let dt = CGFloat(deltaTime)
        for lane in lanes where lane.speed != 0 {
            for node in lane.nodes {
                node.position.x += lane.speed * dt
                if lane.speed > 0 && node.position.x > size.width + 80 { node.position.x = -80 }
                if lane.speed < 0 && node.position.x < -80 { node.position.x = size.width + 80 }
            }
        }

        // 跟著浮木走
        if let log = onLog, hopping == false {
            frog.position.x = log.position.x
            if frog.position.x < -10 || frog.position.x > size.width + 10 { die() }
        }

        guard hopping == false, frogRow < lanes.count else { return }
        let lane = lanes[frogRow]
        if lane.kind == .road {
            for car in lane.nodes where abs(car.position.x - frog.position.x) < columnWidth * 0.66 {
                die()
                return
            }
        }
    }

    private func checkLanding() {
        guard frogRow < lanes.count else { return }
        let lane = lanes[frogRow]
        switch lane.kind {
        case .river:
            var landed: SKNode?
            for log in lane.nodes {
                let halfWidth = log.frame.width / 2
                if abs(log.position.x - frog.position.x) < halfWidth + 6 { landed = log; break }
            }
            if let landed {
                onLog = landed
            } else {
                ArcadeFX.burst(in: gameLayer, at: frog.position, color: .systemBlue, count: 14)
                die()
            }
        case .goal:
            addScore(100)
            level += 1
            flash("過關！LV \(level)", color: accent)
            ArcadeFX.Haptic.success()
            ArcadeFX.burst(in: gameLayer, at: frog.position, color: .systemYellow, count: 24)
            buildLevel()
            placeFrogAtStart()
        default:
            break
        }
    }

    private func die() {
        guard phase == .playing else { return }
        lives -= 1
        livesLabel.text = String(repeating: "♥", count: max(lives, 0))
        ArcadeFX.Haptic.error()
        ArcadeFX.burst(in: gameLayer, at: frog.position, color: .systemRed, count: 18)
        if lives <= 0 {
            endGame()
        } else {
            flash("剩 \(lives) 條命", color: .systemRed, fontSize: 22)
            placeFrogAtStart()
        }
    }
}
