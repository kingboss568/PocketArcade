import SpriteKit

/// 火箭飛行：點擊噴射上升，穿過能量閘門，速度隨分數提升。
final class RocketRushScene: BaseArcadeScene {

    private var rocket: SKNode!
    private var velocityY: CGFloat = 0
    private var gates: [(top: SKShapeNode, bottom: SKShapeNode, scored: Bool)] = []
    private var spawnAccumulator: TimeInterval = 0
    private let gravity: CGFloat = -1500
    private let thrust: CGFloat = 520
    private var scrollSpeed: CGFloat = 170
    private var exhaust: SKEmitterNode!
    private var gapHeight: CGFloat { max(215 - CGFloat(level) * 8, 150) }

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.10, green: 0.05, blue: 0.20, alpha: 1),
                                    bottom: UIColor(red: 0.20, green: 0.07, blue: 0.10, alpha: 1))
        ArcadeFX.addStarfield(to: self, count: 56)
    }

    override func setupGame() {
        rocket = SKNode()
        let body = ArcadeFX.emojiNode("🚀", size: 42)
        body.zRotation = -.pi / 4   // emoji 火箭預設朝右上，轉成朝右
        rocket.addChild(body)
        exhaust = ArcadeFX.trailEmitter(color: .orange, birthRate: 0, lifetime: 0.5, scale: 0.24)
        exhaust.position = CGPoint(x: -20, y: -8)
        rocket.addChild(exhaust)
        rocket.position = CGPoint(x: size.width * 0.30, y: (playTop + playBottom) / 2)
        rocket.zPosition = 50
        gameLayer.addChild(rocket)

        // 上下邊界線
        for y in [playTop, playBottom] {
            let line = SKShapeNode(rect: CGRect(x: 0, y: y - 1, width: size.width, height: 2))
            line.fillColor = accent.withAlphaComponent(0.5)
            line.strokeColor = .clear
            gameLayer.addChild(line)
        }
    }

    override func gameDidStart() {
        velocityY = thrust * 0.55
    }

    override func gameTouchBegan(at point: CGPoint) {
        velocityY = thrust
        exhaust.particleBirthRate = 130
        ArcadeFX.Haptic.light()
    }

    override func gameTouchEnded(at point: CGPoint) {
        exhaust.particleBirthRate = 30
    }

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        let dt = CGFloat(deltaTime)

        velocityY += gravity * dt
        velocityY = max(velocityY, -780)
        rocket.position.y += velocityY * dt
        rocket.zRotation = min(max(velocityY / 1400, -0.5), 0.4)

        // 邊界
        if rocket.position.y > playTop - 20 || rocket.position.y < playBottom + 20 {
            crash()
            return
        }

        // 生成閘門
        spawnAccumulator += deltaTime
        let interval = TimeInterval(max(2.1 - Double(level) * 0.08, 1.45))
        if spawnAccumulator >= interval {
            spawnAccumulator = 0
            spawnGate()
        }

        // 移動閘門 + 碰撞 + 計分
        for index in gates.indices.reversed() {
            gates[index].top.position.x -= scrollSpeed * dt
            gates[index].bottom.position.x -= scrollSpeed * dt
            let gateX = gates[index].top.position.x

            if gates[index].scored == false && gateX < rocket.position.x - 24 {
                gates[index].scored = true
                addScore(10)
                ArcadeFX.floatingScore("+10", at: CGPoint(x: rocket.position.x, y: rocket.position.y + 36), in: gameLayer, color: accent, fontSize: 15)
                ArcadeFX.Haptic.medium()
                if score % 50 == 0 {
                    level += 1
                    scrollSpeed = min(scrollSpeed + 18, 330)
                    flash("加速！LV \(level)", color: accent, fontSize: 22)
                }
            }

            if gates[index].top.frame.insetBy(dx: 6, dy: 6).contains(rocket.position) ||
                gates[index].bottom.frame.insetBy(dx: 6, dy: 6).contains(rocket.position) {
                crash()
                return
            }

            if gateX < -60 {
                gates[index].top.removeFromParent()
                gates[index].bottom.removeFromParent()
                gates.remove(at: index)
            }
        }
    }

    private func spawnGate() {
        let margin: CGFloat = 70
        let gapCenter = CGFloat.random(in: (playBottom + margin + gapHeight / 2)...(playTop - margin - gapHeight / 2))
        let pillarWidth: CGFloat = 56
        let x = size.width + pillarWidth

        func pillar(from bottom: CGFloat, to top: CGFloat) -> SKShapeNode {
            let height = top - bottom
            let node = SKShapeNode(rectOf: CGSize(width: pillarWidth, height: height), cornerRadius: 10)
            node.position = CGPoint(x: x, y: (bottom + top) / 2)
            node.fillColor = SKColor(red: 0.55, green: 0.20, blue: 0.65, alpha: 0.85)
            node.strokeColor = SKColor(red: 0.95, green: 0.45, blue: 1, alpha: 1)
            node.lineWidth = 2
            node.glowWidth = 4
            node.zPosition = 20
            return node
        }

        let topPillar = pillar(from: gapCenter + gapHeight / 2, to: playTop)
        let bottomPillar = pillar(from: playBottom, to: gapCenter - gapHeight / 2)
        gameLayer.addChild(topPillar)
        gameLayer.addChild(bottomPillar)
        gates.append((topPillar, bottomPillar, false))
    }

    private func crash() {
        ArcadeFX.burst(in: gameLayer, at: rocket.position, color: .orange, count: 30, speed: 200)
        ArcadeFX.Haptic.error()
        rocket.run(.sequence([.fadeOut(withDuration: 0.2)]))
        endGame(message: "墜毀！💥")
    }
}
