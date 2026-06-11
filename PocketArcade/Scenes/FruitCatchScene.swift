import SpriteKit

/// 接水果：拖曳籃子接住落下的水果，避開炸彈，Combo 連擊加分。
final class FruitCatchScene: BaseArcadeScene {

    private struct Falling {
        let node: SKLabelNode
        let isBomb: Bool
        let points: Int
        var speed: CGFloat
    }

    private var basket: SKLabelNode!
    private var basketTargetX: CGFloat = 0
    private var fallingObjects: [Falling] = []
    private var spawnAccumulator: TimeInterval = 0
    private var lives = 3
    private var livesLabel: SKLabelNode!
    private var combo = 0
    private var comboLabel: SKLabelNode!
    private var elapsed: TimeInterval = 0

    private let fruits: [(emoji: String, points: Int)] = [
        ("🍎", 10), ("🍌", 10), ("🍇", 15), ("🍓", 15), ("🍊", 10),
        ("🍉", 20), ("🥝", 15), ("🍒", 20), ("🍍", 25)
    ]

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.08, green: 0.14, blue: 0.24, alpha: 1),
                                    bottom: UIColor(red: 0.10, green: 0.07, blue: 0.04, alpha: 1))
    }

    override func setupGame() {
        basketTargetX = size.width / 2

        // 地面
        let ground = SKSpriteNode(color: SKColor(red: 0.18, green: 0.12, blue: 0.07, alpha: 1),
                                  size: CGSize(width: size.width, height: 36))
        ground.position = CGPoint(x: size.width / 2, y: playBottom + 18)
        gameLayer.addChild(ground)

        basket = ArcadeFX.emojiNode("🧺", size: 58)
        basket.position = CGPoint(x: size.width / 2, y: playBottom + 64)
        basket.zPosition = 50
        gameLayer.addChild(basket)

        livesLabel = ArcadeFX.label("♥♥♥", size: 15, color: .systemRed, font: "AvenirNext-Bold")
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.position = CGPoint(x: 14, y: playBottom + 8)
        livesLabel.zPosition = 100
        gameLayer.addChild(livesLabel)

        comboLabel = ArcadeFX.label("", size: 16, color: .systemOrange, font: "AvenirNext-Heavy")
        comboLabel.position = CGPoint(x: size.width - 70, y: playBottom + 10)
        comboLabel.zPosition = 100
        gameLayer.addChild(comboLabel)
    }

    override func gameTouchBegan(at point: CGPoint) { basketTargetX = point.x }
    override func gameTouchMoved(to point: CGPoint, previous: CGPoint) { basketTargetX = point.x }

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        let dt = CGFloat(deltaTime)
        elapsed += deltaTime

        // 難度曲線
        let newLevel = 1 + Int(elapsed / 25)
        if newLevel != level {
            level = newLevel
            flash("LV \(level) 加速！", color: accent, fontSize: 22)
        }

        // 籃子平滑跟隨
        let clamped = min(max(basketTargetX, 34), size.width - 34)
        basket.position.x += (clamped - basket.position.x) * min(1, dt * 16)

        // 生成
        spawnAccumulator += deltaTime
        let interval = max(1.0 - Double(level) * 0.09, 0.40)
        if spawnAccumulator >= interval {
            spawnAccumulator = 0
            spawn()
        }

        // 掉落 + 接取
        for (index, falling) in fallingObjects.enumerated().reversed() {
            falling.node.position.y -= falling.speed * dt

            let caught = abs(falling.node.position.x - basket.position.x) < 42 &&
                abs(falling.node.position.y - (basket.position.y + 12)) < 26

            if caught {
                if falling.isBomb {
                    combo = 0
                    comboLabel.text = ""
                    lives -= 1
                    livesLabel.text = String(repeating: "♥", count: max(lives, 0))
                    ArcadeFX.burst(in: gameLayer, at: falling.node.position, color: .systemRed, count: 28, speed: 190)
                    flash("💥 接到炸彈！", color: .systemRed, fontSize: 24)
                    ArcadeFX.Haptic.error()
                    if lives <= 0 {
                        falling.node.removeFromParent()
                        fallingObjects.remove(at: index)
                        endGame()
                        return
                    }
                } else {
                    combo += 1
                    let points = falling.points * min(1 + combo / 5, 4)
                    addScore(points)
                    comboLabel.text = combo >= 3 ? "COMBO ×\(combo)" : ""
                    ArcadeFX.floatingScore("+\(points)", at: falling.node.position, in: gameLayer, color: .systemYellow, fontSize: 15)
                    ArcadeFX.burst(in: gameLayer, at: falling.node.position, color: .systemYellow, count: 7, speed: 60)
                    ArcadeFX.Haptic.light()
                    basket.run(.sequence([.scale(to: 1.15, duration: 0.07), .scale(to: 1, duration: 0.09)]))
                }
                falling.node.removeFromParent()
                fallingObjects.remove(at: index)
                continue
            }

            // 落地
            if falling.node.position.y < playBottom + 40 {
                if falling.isBomb == false {
                    combo = 0
                    comboLabel.text = ""
                    ArcadeFX.burst(in: gameLayer, at: falling.node.position, color: UIColor(white: 0.6, alpha: 1), count: 6, speed: 40)
                } else {
                    ArcadeFX.burst(in: gameLayer, at: falling.node.position, color: .systemOrange, count: 14, speed: 110)
                }
                falling.node.removeFromParent()
                fallingObjects.remove(at: index)
            }
        }
    }

    private func spawn() {
        let isBomb = Int.random(in: 0..<100) < min(12 + level * 3, 30)
        let node: SKLabelNode
        var points = 0
        if isBomb {
            node = ArcadeFX.emojiNode("💣", size: 40)
            node.run(.repeatForever(.sequence([.rotate(byAngle: 0.3, duration: 0.2), .rotate(byAngle: -0.3, duration: 0.2)])))
        } else {
            let fruit = fruits.randomElement()!
            node = ArcadeFX.emojiNode(fruit.emoji, size: 40)
            points = fruit.points
            node.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: Double.random(in: 2...4))))
        }
        node.position = CGPoint(x: CGFloat.random(in: 34...(size.width - 34)), y: playTop + 30)
        node.zPosition = 20
        gameLayer.addChild(node)
        let speed = CGFloat.random(in: 170...250) + CGFloat(level) * 22
        fallingObjects.append(Falling(node: node, isBomb: isBomb, points: points, speed: speed))
    }
}
