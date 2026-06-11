import SpriteKit

/// 太空侵略者：編隊左右推進、敵方彈幕、拖曳戰機自動開火、波次挑戰。
final class InvaderStormScene: BaseArcadeScene {

    private var ship: SKNode!
    private var shipTargetX: CGFloat = 0
    private var invaders: [SKLabelNode] = []
    private var playerBullets: [SKShapeNode] = []
    private var enemyBullets: [SKShapeNode] = []
    private var formationDirection: CGFloat = 1
    private var formationSpeed: CGFloat = 36
    private var fireAccumulator: TimeInterval = 0
    private var enemyFireAccumulator: TimeInterval = 0
    private var lives = 3
    private var livesLabel: SKLabelNode!
    private var wave = 1
    private var invincibleUntil: TimeInterval = 0

    private let invaderEmojis = ["👾", "👽", "🛸", "🤖"]

    override func setupGame() {
        shipTargetX = size.width / 2

        ship = SKNode()
        let hull = SKShapeNode(path: {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 18))
            path.addLine(to: CGPoint(x: -16, y: -12))
            path.addLine(to: CGPoint(x: 16, y: -12))
            path.closeSubpath()
            return path
        }())
        hull.fillColor = accent
        hull.strokeColor = .white
        hull.lineWidth = 1.5
        hull.glowWidth = 4
        ship.addChild(hull)
        ship.position = CGPoint(x: size.width / 2, y: playBottom + 60)
        ship.zPosition = 30
        gameLayer.addChild(ship)

        livesLabel = ArcadeFX.label("♥♥♥", size: 15, color: .systemRed, font: "AvenirNext-Bold")
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.position = CGPoint(x: 14, y: playBottom)
        livesLabel.zPosition = 100
        gameLayer.addChild(livesLabel)
    }

    override func gameDidStart() { spawnWave() }

    private func spawnWave() {
        flash("WAVE \(wave)", color: accent)
        let cols = 7
        let rowCount = min(3 + wave / 2, 5)
        let spacingX = (size.width - 60) / CGFloat(cols - 1)
        for row in 0..<rowCount {
            for col in 0..<cols {
                let invader = ArcadeFX.emojiNode(invaderEmojis[row % invaderEmojis.count], size: 30)
                invader.position = CGPoint(x: 30 + CGFloat(col) * spacingX,
                                           y: playTop - 60 - CGFloat(row) * 46)
                invader.zPosition = 20
                invader.alpha = 0
                invader.run(.sequence([.wait(forDuration: Double(row * cols + col) * 0.02), .fadeIn(withDuration: 0.2)]))
                // 輕微浮動
                invader.run(.repeatForever(.sequence([
                    .moveBy(x: 0, y: 4, duration: 0.6),
                    .moveBy(x: 0, y: -4, duration: 0.6)
                ])))
                gameLayer.addChild(invader)
                invaders.append(invader)
            }
        }
        formationSpeed = 30 + CGFloat(wave) * 7
    }

    override func gameTouchBegan(at point: CGPoint) { shipTargetX = point.x }
    override func gameTouchMoved(to point: CGPoint, previous: CGPoint) { shipTargetX = point.x }

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        let dt = CGFloat(deltaTime)

        // 戰機移動
        let clamped = min(max(shipTargetX, 24), size.width - 24)
        ship.position.x += (clamped - ship.position.x) * min(1, dt * 13)

        // 閃爍無敵
        let blinking = currentTime < invincibleUntil
        ship.alpha = blinking ? (Int(currentTime * 8) % 2 == 0 ? 0.25 : 0.8) : 1

        // 自動開火
        fireAccumulator += deltaTime
        if fireAccumulator >= max(0.34 - Double(wave) * 0.014, 0.18) {
            fireAccumulator = 0
            let bullet = SKShapeNode(rectOf: CGSize(width: 4, height: 13), cornerRadius: 2)
            bullet.fillColor = accent
            bullet.strokeColor = .clear
            bullet.glowWidth = 3
            bullet.position = CGPoint(x: ship.position.x, y: ship.position.y + 22)
            gameLayer.addChild(bullet)
            playerBullets.append(bullet)
        }

        // 編隊移動
        var hitEdge = false
        var lowestY: CGFloat = .greatestFiniteMagnitude
        for invader in invaders {
            invader.position.x += formationDirection * formationSpeed * dt
            if invader.position.x > size.width - 26 || invader.position.x < 26 { hitEdge = true }
            lowestY = min(lowestY, invader.position.y)
        }
        if hitEdge {
            formationDirection *= -1
            for invader in invaders {
                invader.position.y -= 16
                invader.position.x += formationDirection * 2
            }
        }
        // 攻到底線
        if invaders.isEmpty == false && lowestY < playBottom + 110 {
            endGame(message: "防線失守！")
            return
        }

        // 敵方開火
        enemyFireAccumulator += deltaTime
        if enemyFireAccumulator >= max(1.1 - Double(wave) * 0.07, 0.45), let shooter = invaders.randomElement() {
            enemyFireAccumulator = 0
            let bullet = SKShapeNode(circleOfRadius: 5)
            bullet.fillColor = .systemRed
            bullet.strokeColor = .white.withAlphaComponent(0.6)
            bullet.glowWidth = 3
            bullet.position = CGPoint(x: shooter.position.x, y: shooter.position.y - 18)
            gameLayer.addChild(bullet)
            enemyBullets.append(bullet)
        }

        // 玩家子彈
        for (index, bullet) in playerBullets.enumerated().reversed() {
            bullet.position.y += 520 * dt
            var removed = false
            for (invaderIndex, invader) in invaders.enumerated().reversed() {
                if hypot(invader.position.x - bullet.position.x, invader.position.y - bullet.position.y) < 22 {
                    addScore(10 + wave * 2)
                    ArcadeFX.burst(in: gameLayer, at: invader.position, color: .green, count: 10, speed: 90)
                    ArcadeFX.Haptic.medium()
                    invader.removeFromParent()
                    invaders.remove(at: invaderIndex)
                    bullet.removeFromParent()
                    playerBullets.remove(at: index)
                    removed = true
                    break
                }
            }
            if removed == false && bullet.position.y > playTop + 20 {
                bullet.removeFromParent()
                playerBullets.remove(at: index)
            }
        }

        // 敵方子彈
        for (index, bullet) in enemyBullets.enumerated().reversed() {
            bullet.position.y -= (240 + CGFloat(wave) * 18) * dt
            if blinking == false && hypot(bullet.position.x - ship.position.x, bullet.position.y - ship.position.y) < 20 {
                bullet.removeFromParent()
                enemyBullets.remove(at: index)
                hitShip(currentTime: currentTime)
                continue
            }
            if bullet.position.y < playBottom - 20 {
                bullet.removeFromParent()
                enemyBullets.remove(at: index)
            }
        }

        // 波次完成
        if invaders.isEmpty && phase == .playing {
            wave += 1
            level = wave
            addScore(100)
            enemyBullets.forEach { $0.removeFromParent() }
            enemyBullets.removeAll()
            run(.sequence([.wait(forDuration: 0.9), .run { [weak self] in self?.spawnWave() }]))
        }
    }

    private func hitShip(currentTime: TimeInterval) {
        lives -= 1
        livesLabel.text = String(repeating: "♥", count: max(lives, 0))
        ArcadeFX.burst(in: gameLayer, at: ship.position, color: .systemRed, count: 24, speed: 150)
        ArcadeFX.Haptic.error()
        if lives <= 0 {
            endGame()
        } else {
            invincibleUntil = currentTime + 2
            flash("剩 \(lives) 條命", color: .systemRed, fontSize: 22)
        }
    }
}
