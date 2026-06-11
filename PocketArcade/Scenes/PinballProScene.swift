import SpriteKit

/// 彈珠台：SpriteKit 物理、左右撥桿、保險桿得分、3 顆球。
final class PinballProScene: BaseArcadeScene, SKPhysicsContactDelegate {

    private enum Category {
        static let ball: UInt32 = 1 << 0
        static let wall: UInt32 = 1 << 1
        static let bumper: UInt32 = 1 << 2
        static let flipper: UInt32 = 1 << 3
    }

    private var ball: SKShapeNode?
    private var leftFlipper: SKShapeNode!
    private var rightFlipper: SKShapeNode!
    private var ballsLeft = 3
    private var ballsLabel: SKLabelNode!
    private var multiplier = 1
    private var lastBumperHit: TimeInterval = 0

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.14, green: 0.06, blue: 0.24, alpha: 1),
                                    bottom: UIColor(red: 0.05, green: 0.02, blue: 0.10, alpha: 1))
        ArcadeFX.addStarfield(to: self, count: 30)
    }

    override func setupGame() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -5.2)
        physicsWorld.contactDelegate = self

        let left: CGFloat = 8
        let right = size.width - 8
        let top = playTop - 6
        let bottom = playBottom + 30
        let flipperY = bottom + 70

        // 外牆（底部留排水口）
        let path = CGMutablePath()
        path.move(to: CGPoint(x: left + 60, y: bottom))
        path.addLine(to: CGPoint(x: left, y: flipperY + 60))
        path.addLine(to: CGPoint(x: left, y: top - 40))
        path.addQuadCurve(to: CGPoint(x: left + 60, y: top), control: CGPoint(x: left, y: top))
        path.addLine(to: CGPoint(x: right - 60, y: top))
        path.addQuadCurve(to: CGPoint(x: right, y: top - 40), control: CGPoint(x: right, y: top))
        path.addLine(to: CGPoint(x: right, y: flipperY + 60))
        path.addLine(to: CGPoint(x: right - 60, y: bottom))

        let walls = SKShapeNode(path: path)
        walls.strokeColor = accent.withAlphaComponent(0.85)
        walls.lineWidth = 3
        walls.glowWidth = 3
        walls.physicsBody = SKPhysicsBody(edgeChainFrom: path)
        walls.physicsBody?.friction = 0.05
        walls.physicsBody?.restitution = 0.55
        walls.physicsBody?.categoryBitMask = Category.wall
        gameLayer.addChild(walls)

        // 保險桿
        let bumperPositions = [
            CGPoint(x: size.width * 0.30, y: top - 150),
            CGPoint(x: size.width * 0.70, y: top - 150),
            CGPoint(x: size.width * 0.50, y: top - 250),
            CGPoint(x: size.width * 0.26, y: top - 330),
            CGPoint(x: size.width * 0.74, y: top - 330)
        ]
        let bumperColors: [SKColor] = [.systemPink, .systemCyan, .systemYellow, .systemGreen, .systemOrange]
        for (index, position) in bumperPositions.enumerated() {
            let bumper = SKShapeNode(circleOfRadius: 24)
            bumper.fillColor = bumperColors[index].withAlphaComponent(0.35)
            bumper.strokeColor = bumperColors[index]
            bumper.lineWidth = 2.5
            bumper.glowWidth = 4
            bumper.position = position
            bumper.name = "bumper"
            bumper.physicsBody = SKPhysicsBody(circleOfRadius: 24)
            bumper.physicsBody?.isDynamic = false
            bumper.physicsBody?.restitution = 1.35
            bumper.physicsBody?.categoryBitMask = Category.bumper
            bumper.physicsBody?.contactTestBitMask = Category.ball
            gameLayer.addChild(bumper)
        }

        // 撥桿上方的斜面（slingshot）
        for isLeft in [true, false] {
            let slingPath = CGMutablePath()
            let x: CGFloat = isLeft ? left + 18 : right - 18
            let inner: CGFloat = isLeft ? size.width * 0.30 : size.width * 0.70
            slingPath.move(to: CGPoint(x: x, y: flipperY + 110))
            slingPath.addLine(to: CGPoint(x: inner, y: flipperY + 18))
            let sling = SKShapeNode(path: slingPath)
            sling.strokeColor = accent.withAlphaComponent(0.7)
            sling.lineWidth = 3
            sling.physicsBody = SKPhysicsBody(edgeChainFrom: slingPath)
            sling.physicsBody?.restitution = 0.9
            sling.physicsBody?.categoryBitMask = Category.wall
            gameLayer.addChild(sling)
        }

        // 撥桿
        leftFlipper = makeFlipper(isLeft: true)
        leftFlipper.position = CGPoint(x: size.width * 0.30, y: flipperY)
        gameLayer.addChild(leftFlipper)

        rightFlipper = makeFlipper(isLeft: false)
        rightFlipper.position = CGPoint(x: size.width * 0.70, y: flipperY)
        gameLayer.addChild(rightFlipper)

        ballsLabel = ArcadeFX.label("●●●", size: 15, color: accent, font: "AvenirNext-Bold")
        ballsLabel.horizontalAlignmentMode = .left
        ballsLabel.position = CGPoint(x: 16, y: playBottom)
        ballsLabel.zPosition = 100
        gameLayer.addChild(ballsLabel)
    }

    private func makeFlipper(isLeft: Bool) -> SKShapeNode {
        let length: CGFloat = 74
        let rect = CGRect(x: isLeft ? 0 : -length, y: -9, width: length, height: 18)
        let flipper = SKShapeNode(rect: rect, cornerRadius: 9)
        flipper.fillColor = accent
        flipper.strokeColor = .white.withAlphaComponent(0.8)
        flipper.lineWidth = 1.5
        flipper.glowWidth = 3
        flipper.zRotation = isLeft ? -0.42 : 0.42
        flipper.physicsBody = SKPhysicsBody(polygonFrom: CGPath(roundedRect: rect, cornerWidth: 9, cornerHeight: 9, transform: nil))
        flipper.physicsBody?.isDynamic = false
        flipper.physicsBody?.restitution = 0.35
        flipper.physicsBody?.friction = 0.2
        flipper.physicsBody?.categoryBitMask = Category.flipper
        return flipper
    }

    override func gameDidStart() {
        launchBall()
    }

    private func launchBall() {
        let node = SKShapeNode(circleOfRadius: 11)
        node.fillColor = .white
        node.strokeColor = SKColor(white: 0.85, alpha: 1)
        node.lineWidth = 1
        node.glowWidth = 4
        node.position = CGPoint(x: size.width - 36, y: playTop - 70)
        node.physicsBody = SKPhysicsBody(circleOfRadius: 11)
        node.physicsBody?.restitution = 0.5
        node.physicsBody?.friction = 0.04
        node.physicsBody?.linearDamping = 0.12
        node.physicsBody?.mass = 0.05
        node.physicsBody?.categoryBitMask = Category.ball
        node.physicsBody?.contactTestBitMask = Category.bumper
        node.physicsBody?.usesPreciseCollisionDetection = true
        gameLayer.addChild(node)
        node.physicsBody?.applyImpulse(CGVector(dx: CGFloat.random(in: -0.4...0.1), dy: -0.5))
        ball = node
        multiplier = 1
    }

    // MARK: - Flipper control

    override func gameTouchBegan(at point: CGPoint) {
        if point.x < size.width / 2 {
            flip(leftFlipper, to: 0.5, isLeft: true)
        } else {
            flip(rightFlipper, to: -0.5, isLeft: false)
        }
        ArcadeFX.Haptic.light()
    }

    override func gameTouchEnded(at point: CGPoint) {
        leftFlipper.run(.rotate(toAngle: -0.42, duration: 0.10))
        rightFlipper.run(.rotate(toAngle: 0.42, duration: 0.10))
    }

    private func flip(_ flipper: SKShapeNode, to angle: CGFloat, isLeft: Bool) {
        flipper.run(.rotate(toAngle: angle, duration: 0.07, shortestUnitArc: true))
        // 模擬撥桿擊球力道
        if let ball, ball.frame.insetBy(dx: -34, dy: -34).intersects(flipper.frame) {
            ball.physicsBody?.applyImpulse(CGVector(dx: isLeft ? 0.22 : -0.22, dy: 1.5))
        }
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let nodes = [contact.bodyA.node, contact.bodyB.node]
        guard let bumper = nodes.first(where: { $0?.name == "bumper" }) ?? nil else { return }
        let now = CACurrentMediaTime()
        if now - lastBumperHit < 1.2 { multiplier = min(multiplier + 1, 5) } else { multiplier = 1 }
        lastBumperHit = now
        let points = 25 * multiplier
        addScore(points)
        ArcadeFX.floatingScore("+\(points)", at: bumper.position, in: gameLayer, color: .systemYellow, fontSize: 15)
        ArcadeFX.burst(in: gameLayer, at: bumper.position, color: (bumper as? SKShapeNode)?.strokeColor ?? .white, count: 10, speed: 70)
        bumper.run(.sequence([.scale(to: 1.25, duration: 0.07), .scale(to: 1, duration: 0.1)]))
        ArcadeFX.Haptic.medium()
        if score > level * 500 { level += 1 }
    }

    // MARK: - Drain

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        guard let current = ball else { return }
        if current.position.y < playBottom - 10 {
            current.removeFromParent()
            ball = nil
            ballsLeft -= 1
            ballsLabel.text = String(repeating: "●", count: max(ballsLeft, 0))
            ArcadeFX.Haptic.error()
            if ballsLeft <= 0 {
                endGame()
            } else {
                flash("剩 \(ballsLeft) 顆球", color: .systemOrange, fontSize: 22)
                run(.sequence([.wait(forDuration: 0.8), .run { [weak self] in self?.launchBall() }]))
            }
        }
    }
}
