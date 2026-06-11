import SpriteKit

/// 射擊隕石：拖曳移動戰機、自動連射、大隕石分裂成小隕石、波次挑戰。
final class AsteroidAceScene: BaseArcadeScene {

    private struct Asteroid {
        let node: SKShapeNode
        var velocity: CGVector
        var size: Int  // 3 大、2 中、1 小
        var spin: CGFloat
    }

    private var ship: SKNode!
    private var shipTarget: CGPoint = .zero
    private var bullets: [SKShapeNode] = []
    private var asteroids: [Asteroid] = []
    private var fireAccumulator: TimeInterval = 0
    private var lives = 3
    private var livesLabel: SKLabelNode!
    private var invincibleUntil: TimeInterval = 0
    private var wave = 1

    override func setupGame() {
        shipTarget = CGPoint(x: size.width / 2, y: playBottom + 110)

        ship = SKNode()
        let hull = SKShapeNode(path: {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: -14, y: -14))
            path.addLine(to: CGPoint(x: 0, y: -7))
            path.addLine(to: CGPoint(x: 14, y: -14))
            path.closeSubpath()
            return path
        }())
        hull.fillColor = accent
        hull.strokeColor = .white
        hull.lineWidth = 1.5
        hull.glowWidth = 4
        ship.addChild(hull)
        let exhaust = ArcadeFX.trailEmitter(color: UIColor.orange, birthRate: 50, lifetime: 0.3, scale: 0.14)
        exhaust.position = CGPoint(x: 0, y: -16)
        ship.addChild(exhaust)
        ship.position = shipTarget
        ship.zPosition = 20
        gameLayer.addChild(ship)

        livesLabel = ArcadeFX.label("♥♥♥", size: 15, color: .systemRed, font: "AvenirNext-Bold")
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.position = CGPoint(x: 14, y: playBottom)
        livesLabel.zPosition = 100
        gameLayer.addChild(livesLabel)
    }

    override func gameDidStart() {
        spawnWave()
    }

    private func spawnWave() {
        flash("WAVE \(wave)", color: accent)
        for _ in 0..<(2 + wave) {
            spawnAsteroid(size: 3, at: nil)
        }
    }

    private func spawnAsteroid(size asteroidSize: Int, at position: CGPoint?) {
        let radius = CGFloat(asteroidSize) * 14
        // 不規則多邊形
        let path = CGMutablePath()
        let points = 9
        for i in 0..<points {
            let angle = CGFloat(i) / CGFloat(points) * 2 * .pi
            let r = radius * CGFloat.random(in: 0.75...1.15)
            let point = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()

        let node = SKShapeNode(path: path)
        let gray = CGFloat.random(in: 0.45...0.65)
        node.fillColor = SKColor(red: gray * 0.9, green: gray * 0.82, blue: gray, alpha: 1)
        node.strokeColor = .white.withAlphaComponent(0.5)
        node.lineWidth = 1.5

        let startPosition: CGPoint
        if let position {
            startPosition = position
        } else {
            // 從頂部或側邊進場，避開戰機附近
            startPosition = CGPoint(x: .random(in: 30...(self.size.width - 30)), y: playTop + 50)
        }
        node.position = startPosition
        node.zPosition = 10
        gameLayer.addChild(node)

        let speed = CGFloat.random(in: 40...90) + CGFloat(wave) * 8
        let angle = CGFloat.random(in: (.pi * 1.15)...(.pi * 1.85))
        asteroids.append(Asteroid(node: node,
                                  velocity: CGVector(dx: cos(angle) * speed * 0.6, dy: sin(angle) * speed),
                                  size: asteroidSize,
                                  spin: CGFloat.random(in: -1.6...1.6)))
    }

    // MARK: - Touch

    override func gameTouchBegan(at point: CGPoint) { shipTarget = point }
    override func gameTouchMoved(to point: CGPoint, previous: CGPoint) { shipTarget = point }

    // MARK: - Update

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        let dt = CGFloat(deltaTime)

        // 戰機平滑移動
        let clampedX = min(max(shipTarget.x, 22), size.width - 22)
        let clampedY = min(max(shipTarget.y + 60, playBottom + 50), playTop - 60)
        ship.position.x += (clampedX - ship.position.x) * min(1, dt * 11)
        ship.position.y += (clampedY - ship.position.y) * min(1, dt * 11)

        // 自動開火
        fireAccumulator += deltaTime
        let fireInterval = max(0.30 - Double(level) * 0.014, 0.13)
        if fireAccumulator >= fireInterval {
            fireAccumulator = 0
            fire()
        }

        // 子彈
        for (index, bullet) in bullets.enumerated().reversed() {
            bullet.position.y += 540 * dt
            if bullet.position.y > playTop + 20 {
                bullet.removeFromParent()
                bullets.remove(at: index)
            }
        }

        // 隕石
        let blink = currentTime < invincibleUntil
        ship.alpha = blink ? (Int(currentTime * 8) % 2 == 0 ? 0.25 : 0.8) : 1

        for (index, asteroid) in asteroids.enumerated().reversed() {
            asteroid.node.position.x += asteroid.velocity.dx * dt
            asteroid.node.position.y += asteroid.velocity.dy * dt
            asteroid.node.zRotation += asteroid.spin * dt

            // 左右環繞
            if asteroid.node.position.x < -50 { asteroid.node.position.x = size.width + 50 }
            if asteroid.node.position.x > size.width + 50 { asteroid.node.position.x = -50 }
            // 掉出底部 → 回到頂部
            if asteroid.node.position.y < playBottom - 60 {
                asteroid.node.position.y = playTop + 50
            }

            let radius = CGFloat(asteroid.size) * 14

            // 子彈碰撞
            for (bulletIndex, bullet) in bullets.enumerated().reversed() {
                if hypot(bullet.position.x - asteroid.node.position.x, bullet.position.y - asteroid.node.position.y) < radius {
                    bullet.removeFromParent()
                    bullets.remove(at: bulletIndex)
                    breakAsteroid(at: index)
                    break
                }
            }
        }

        // 戰機碰撞
        if blink == false {
            for asteroid in asteroids {
                let radius = CGFloat(asteroid.size) * 14
                if hypot(ship.position.x - asteroid.node.position.x, ship.position.y - asteroid.node.position.y) < radius + 12 {
                    hitShip(currentTime: currentTime)
                    break
                }
            }
        }

        if asteroids.isEmpty && phase == .playing {
            wave += 1
            level = wave
            addScore(100)
            run(.sequence([.wait(forDuration: 0.8), .run { [weak self] in self?.spawnWave() }]))
        }
    }

    private func fire() {
        let bullet = SKShapeNode(rectOf: CGSize(width: 4, height: 14), cornerRadius: 2)
        bullet.fillColor = .systemYellow
        bullet.strokeColor = .clear
        bullet.glowWidth = 3
        bullet.position = CGPoint(x: ship.position.x, y: ship.position.y + 24)
        bullet.zPosition = 5
        gameLayer.addChild(bullet)
        bullets.append(bullet)
    }

    private func breakAsteroid(at index: Int) {
        guard index < asteroids.count else { return }
        let asteroid = asteroids[index]
        let position = asteroid.node.position
        let points = (4 - asteroid.size) * 15
        addScore(points)
        ArcadeFX.floatingScore("+\(points)", at: position, in: gameLayer, color: .systemYellow, fontSize: 14)
        ArcadeFX.burst(in: gameLayer, at: position, color: UIColor(white: 0.7, alpha: 1), count: 12, speed: 100)
        ArcadeFX.Haptic.medium()
        asteroid.node.removeFromParent()
        asteroids.remove(at: index)

        if asteroid.size > 1 {
            for _ in 0..<2 {
                spawnAsteroid(size: asteroid.size - 1, at: position)
            }
        }
    }

    private func hitShip(currentTime: TimeInterval) {
        lives -= 1
        livesLabel.text = String(repeating: "♥", count: max(lives, 0))
        ArcadeFX.burst(in: gameLayer, at: ship.position, color: .systemRed, count: 26, speed: 160)
        ArcadeFX.Haptic.error()
        if lives <= 0 {
            endGame()
        } else {
            invincibleUntil = currentTime + 2.2
            flash("剩 \(lives) 條命", color: .systemRed, fontSize: 22)
        }
    }
}
