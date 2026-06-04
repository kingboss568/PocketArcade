import SpriteKit

final class AsteroidAceScene: BaseArcadeScene {
    private let ship = SKShapeNode(rectOf: CGSize(width: 44, height: 22), cornerRadius: 6)
    private var lastShot: TimeInterval = 0
    private var lastAsteroid: TimeInterval = 0

    init(game: GameModel) { super.init(gameID: game.id, title: game.title) }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func startGame() {
        ship.fillColor = .systemCyan
        ship.strokeColor = .white
        ship.position = CGPoint(x: size.width / 2, y: 90)
        addChild(ship)
        addInstruction("左右滑動飛船，點擊加速射擊")
    }

    override func update(_ currentTime: TimeInterval) {
        if currentTime - lastShot > 0.28 {
            lastShot = currentTime
            shoot()
        }
        if currentTime - lastAsteroid > max(0.28, 0.75 - Double(level) * 0.04) {
            lastAsteroid = currentTime
            spawnAsteroid()
        }
        for bullet in children where bullet.name == "bullet" {
            bullet.position.y += 8
            if bullet.position.y > size.height { bullet.removeFromParent() }
        }
        for asteroid in children where asteroid.name == "asteroid" || asteroid.name == "boss" {
            asteroid.position.y -= asteroid.name == "boss" ? 2.0 : 3.6
            if asteroid.position.y < 42 { asteroid.removeFromParent() }
            if asteroid.frame.intersects(ship.frame) {
                asteroid.removeFromParent()
                score = max(0, score - 20)
                flash("HIT", color: .systemRed)
            }
            for bullet in children where bullet.name == "bullet" && bullet.frame.intersects(asteroid.frame) {
                bullet.removeFromParent()
                asteroid.removeFromParent()
                addScore(asteroid.name == "boss" ? 120 : 15)
                if score / 300 + 1 > level { level += 1 }
                break
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let x = touches.first?.location(in: self).x else { return }
        ship.position.x = min(max(28, x), size.width - 28)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastShot = 0
        shoot()
    }

    private func shoot() {
        let bullet = SKShapeNode(rectOf: CGSize(width: 5, height: 18), cornerRadius: 2)
        bullet.name = "bullet"
        bullet.fillColor = .systemYellow
        bullet.strokeColor = .clear
        bullet.position = CGPoint(x: ship.position.x, y: ship.position.y + 28)
        addChild(bullet)
    }

    private func spawnAsteroid() {
        let boss = Int.random(in: 0..<12) == 0
        let asteroid = SKShapeNode(circleOfRadius: boss ? 32 : CGFloat.random(in: 14...24))
        asteroid.name = boss ? "boss" : "asteroid"
        asteroid.fillColor = boss ? .systemRed : .gray
        asteroid.strokeColor = .white.withAlphaComponent(0.5)
        asteroid.position = CGPoint(x: CGFloat.random(in: 30...(size.width - 30)), y: size.height - 98)
        addChild(asteroid)
    }
}
