import SpriteKit

/// 磚塊爆破：拖曳球拍、彩色磚牆、道具掉落（加寬、多球、愛心）、過關升級。
final class BrickBlitzScene: BaseArcadeScene {

    private struct Ball {
        let node: SKNode
        var velocity: CGVector
    }

    private struct PowerUp {
        let node: SKNode
        let kind: Kind
        enum Kind: CaseIterable { case widen, multiball, life }
    }

    private var paddle: SKShapeNode!
    private var paddleTargetX: CGFloat = 0
    private var paddleWidth: CGFloat = 96
    private var balls: [Ball] = []
    private var bricks: [SKShapeNode] = []
    private var powerUps: [PowerUp] = []
    private var lives = 3
    private var livesLabel: SKLabelNode!
    private var ballSpeed: CGFloat = 380
    private let ballRadius: CGFloat = 8

    private var brickColors: [SKColor] {
        [SKColor(red: 1, green: 0.36, blue: 0.42, alpha: 1),
         SKColor(red: 1, green: 0.62, blue: 0.26, alpha: 1),
         SKColor(red: 1, green: 0.85, blue: 0.30, alpha: 1),
         SKColor(red: 0.36, green: 0.90, blue: 0.52, alpha: 1),
         SKColor(red: 0.34, green: 0.72, blue: 1, alpha: 1),
         SKColor(red: 0.72, green: 0.50, blue: 1, alpha: 1)]
    }

    override func setupGame() {
        paddleTargetX = size.width / 2

        paddle = SKShapeNode(rectOf: CGSize(width: paddleWidth, height: 16), cornerRadius: 8)
        paddle.fillColor = accent
        paddle.strokeColor = .white.withAlphaComponent(0.85)
        paddle.lineWidth = 1.5
        paddle.glowWidth = 5
        paddle.position = CGPoint(x: size.width / 2, y: playBottom + 46)
        gameLayer.addChild(paddle)

        livesLabel = ArcadeFX.label(heartString(), size: 15, color: .systemRed, font: "AvenirNext-Bold")
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.position = CGPoint(x: 16, y: playBottom + 6)
        livesLabel.zPosition = 100
        gameLayer.addChild(livesLabel)

        buildBricks()
        spawnBall()
    }

    private func heartString() -> String { String(repeating: "♥", count: max(lives, 0)) }

    private func buildBricks() {
        bricks.forEach { $0.removeFromParent() }
        bricks.removeAll()
        let columns = 7
        let rows = min(4 + level, 9)
        let margin: CGFloat = 14
        let spacing: CGFloat = 6
        let brickWidth = (size.width - margin * 2 - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        let brickHeight: CGFloat = 22
        let topY = playTop - 36

        for row in 0..<rows {
            for col in 0..<columns {
                let brick = SKShapeNode(rectOf: CGSize(width: brickWidth, height: brickHeight), cornerRadius: 5)
                let color = brickColors[row % brickColors.count]
                brick.fillColor = color
                brick.strokeColor = .white.withAlphaComponent(0.35)
                brick.lineWidth = 1
                brick.position = CGPoint(
                    x: margin + brickWidth / 2 + CGFloat(col) * (brickWidth + spacing),
                    y: topY - CGFloat(row) * (brickHeight + spacing)
                )
                brick.userData = ["hp": row < 2 ? 2 : 1, "color": color]
                brick.alpha = 0
                brick.run(.sequence([.wait(forDuration: Double(row) * 0.05), .fadeIn(withDuration: 0.25)]))
                gameLayer.addChild(brick)
                bricks.append(brick)
            }
        }
    }

    private func spawnBall(at position: CGPoint? = nil) {
        let node = ArcadeFX.glowDot(radius: ballRadius, color: .white)
        node.position = position ?? CGPoint(x: paddle.position.x, y: paddle.position.y + 30)
        gameLayer.addChild(node)
        let angle = CGFloat.random(in: (.pi * 0.32)...(.pi * 0.68))
        balls.append(Ball(node: node, velocity: CGVector(dx: cos(angle) * ballSpeed, dy: sin(angle) * ballSpeed)))
    }

    // MARK: - Touch

    override func gameTouchBegan(at point: CGPoint) { paddleTargetX = point.x }
    override func gameTouchMoved(to point: CGPoint, previous: CGPoint) { paddleTargetX = point.x }

    // MARK: - Update

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        let dt = CGFloat(deltaTime)

        // 球拍平滑跟隨
        let halfPaddle = paddleWidth / 2
        let clampedX = min(max(paddleTargetX, halfPaddle + 8), size.width - halfPaddle - 8)
        paddle.position.x += (clampedX - paddle.position.x) * min(1, dt * 18)

        // 道具掉落
        for (index, powerUp) in powerUps.enumerated().reversed() {
            powerUp.node.position.y -= 150 * dt
            if abs(powerUp.node.position.x - paddle.position.x) < halfPaddle + 14,
               abs(powerUp.node.position.y - paddle.position.y) < 22 {
                applyPowerUp(powerUp.kind)
                powerUp.node.removeFromParent()
                powerUps.remove(at: index)
            } else if powerUp.node.position.y < playBottom {
                powerUp.node.removeFromParent()
                powerUps.remove(at: index)
            }
        }

        // 球運動
        for (index, var ball) in balls.enumerated().reversed() {
            var pos = ball.node.position
            pos.x += ball.velocity.dx * dt
            pos.y += ball.velocity.dy * dt

            // 牆壁
            if pos.x < ballRadius + 4 { pos.x = ballRadius + 4; ball.velocity.dx = abs(ball.velocity.dx); ArcadeFX.Haptic.light() }
            if pos.x > size.width - ballRadius - 4 { pos.x = size.width - ballRadius - 4; ball.velocity.dx = -abs(ball.velocity.dx); ArcadeFX.Haptic.light() }
            if pos.y > playTop - ballRadius { pos.y = playTop - ballRadius; ball.velocity.dy = -abs(ball.velocity.dy) }

            // 球拍
            if ball.velocity.dy < 0,
               abs(pos.y - paddle.position.y) < ballRadius + 9,
               abs(pos.x - paddle.position.x) < halfPaddle + ballRadius {
                let offset = (pos.x - paddle.position.x) / halfPaddle
                let angle = CGFloat.pi / 2 - offset * (.pi * 0.36)
                let speed = min(hypot(ball.velocity.dx, ball.velocity.dy) * 1.015, 660)
                ball.velocity = CGVector(dx: cos(angle) * speed, dy: abs(sin(angle)) * speed)
                pos.y = paddle.position.y + ballRadius + 9
                ArcadeFX.Haptic.light()
            }

            // 磚塊
            for (brickIndex, brick) in bricks.enumerated().reversed() {
                let frame = brick.frame.insetBy(dx: -ballRadius, dy: -ballRadius)
                if frame.contains(pos) {
                    let dx = min(abs(pos.x - frame.minX), abs(pos.x - frame.maxX))
                    let dy = min(abs(pos.y - frame.minY), abs(pos.y - frame.maxY))
                    if dx < dy { ball.velocity.dx *= -1 } else { ball.velocity.dy *= -1 }
                    hitBrick(at: brickIndex)
                    break
                }
            }

            // 掉出底部
            if pos.y < playBottom - 20 {
                ball.node.removeFromParent()
                balls.remove(at: index)
                continue
            }

            ball.node.position = pos
            balls[index] = ball
        }

        if balls.isEmpty { loseLife() }
        if bricks.isEmpty { advanceLevel() }
    }

    // MARK: - Game logic

    private func hitBrick(at index: Int) {
        let brick = bricks[index]
        var hp = brick.userData?["hp"] as? Int ?? 1
        hp -= 1
        if hp <= 0 {
            let color = brick.userData?["color"] as? SKColor ?? accent
            ArcadeFX.burst(in: gameLayer, at: brick.position, color: color, count: 12)
            ArcadeFX.floatingScore("+10", at: brick.position, in: gameLayer, color: color, fontSize: 15)
            if Int.random(in: 0..<9) == 0 { dropPowerUp(from: brick.position) }
            brick.removeFromParent()
            bricks.remove(at: index)
            addScore(10)
            ArcadeFX.Haptic.medium()
        } else {
            brick.userData?["hp"] = hp
            brick.alpha = 0.55
            addScore(5)
        }
    }

    private func dropPowerUp(from position: CGPoint) {
        let kind = PowerUp.Kind.allCases.randomElement()!
        let symbol: String
        let color: SKColor
        switch kind {
        case .widen: symbol = "↔"; color = .systemCyan
        case .multiball: symbol = "●●"; color = .systemOrange
        case .life: symbol = "♥"; color = .systemRed
        }
        let node = SKNode()
        let bg = SKShapeNode(circleOfRadius: 13)
        bg.fillColor = color.withAlphaComponent(0.9)
        bg.strokeColor = .white
        bg.lineWidth = 1.2
        bg.glowWidth = 3
        node.addChild(bg)
        let label = ArcadeFX.label(symbol, size: 12, color: .white, font: "AvenirNext-Heavy")
        node.addChild(label)
        node.position = position
        gameLayer.addChild(node)
        powerUps.append(PowerUp(node: node, kind: kind))
    }

    private func applyPowerUp(_ kind: PowerUp.Kind) {
        ArcadeFX.Haptic.success()
        switch kind {
        case .widen:
            paddleWidth = min(paddleWidth + 30, 170)
            resizePaddle()
            flash("球拍加寬！", color: .systemCyan, fontSize: 22)
        case .multiball:
            if let first = balls.first { spawnBall(at: first.node.position) } else { spawnBall() }
            flash("多球模式！", color: .systemOrange, fontSize: 22)
        case .life:
            lives = min(lives + 1, 5)
            livesLabel.text = heartString()
            flash("+1 生命", color: .systemRed, fontSize: 22)
        }
        addScore(20)
    }

    private func resizePaddle() {
        let newPath = CGPath(roundedRect: CGRect(x: -paddleWidth / 2, y: -8, width: paddleWidth, height: 16), cornerWidth: 8, cornerHeight: 8, transform: nil)
        paddle.path = newPath
    }

    private func loseLife() {
        lives -= 1
        livesLabel.text = heartString()
        ArcadeFX.Haptic.error()
        if lives <= 0 {
            endGame()
        } else {
            flash("剩 \(lives) 條命", color: .systemRed)
            paddleWidth = 96
            resizePaddle()
            spawnBall()
        }
    }

    private func advanceLevel() {
        level += 1
        ballSpeed = min(ballSpeed + 30, 560)
        addScore(100)
        flash("LEVEL \(level)！", color: accent)
        ArcadeFX.Haptic.success()
        balls.forEach { $0.node.removeFromParent() }
        balls.removeAll()
        buildBricks()
        run(.sequence([.wait(forDuration: 0.7), .run { [weak self] in self?.spawnBall() }]))
    }
}
