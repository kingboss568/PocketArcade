import SpriteKit

final class FrogDashScene: BaseArcadeScene {
    private let frog = SKShapeNode(circleOfRadius: 13)
    private var lastSpawn: TimeInterval = 0

    init(game: GameModel) { super.init(gameID: game.id, title: game.title) }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func startGame() {
        frog.fillColor = .systemGreen
        frog.strokeColor = .white
        frog.position = CGPoint(x: size.width / 2, y: 86)
        addChild(frog)
        for lane in 0..<6 {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
            line.strokeColor = .white.withAlphaComponent(0.16)
            line.position = CGPoint(x: size.width / 2, y: 150 + CGFloat(lane) * 70)
            addChild(line)
        }
        addInstruction("滑動青蛙穿越車道與河流")
    }

    override func update(_ currentTime: TimeInterval) {
        if currentTime - lastSpawn > 0.55 {
            lastSpawn = currentTime
            spawnObstacle()
        }
        for node in children where node.name == "car" {
            node.position.x += (node.userData?["speed"] as? CGFloat ?? 90) / 60
            if node.position.x > size.width + 80 { node.removeFromParent() }
            if node.frame.intersects(frog.frame) {
                frog.position = CGPoint(x: size.width / 2, y: 86)
                flash("SPLASH", color: .systemRed)
            }
        }
        if frog.position.y > size.height - 120 {
            addScore(100)
            level += 1
            frog.position = CGPoint(x: size.width / 2, y: 86)
            flash("SAFE!")
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let start = touch.previousLocation(in: self)
        let end = touch.location(in: self)
        let delta = CGPoint(x: end.x - start.x, y: end.y - start.y)
        if abs(delta.x) > abs(delta.y) {
            frog.position.x += delta.x > 0 ? 34 : -34
        } else {
            frog.position.y += delta.y > 0 ? 44 : -44
        }
        frog.position.x = min(max(20, frog.position.x), size.width - 20)
        frog.position.y = min(max(80, frog.position.y), size.height - 90)
    }

    private func spawnObstacle() {
        let y = 150 + CGFloat(Int.random(in: 0..<6)) * 70
        let car = SKShapeNode(rectOf: CGSize(width: 52, height: 24), cornerRadius: 7)
        car.name = "car"
        car.fillColor = [.systemRed, .systemOrange, .systemBlue].randomElement() ?? .systemRed
        car.strokeColor = .white.withAlphaComponent(0.4)
        car.position = CGPoint(x: -60, y: y)
        car.userData = NSMutableDictionary()
        car.userData?["speed"] = CGFloat.random(in: 70...180)
        addChild(car)
    }
}
