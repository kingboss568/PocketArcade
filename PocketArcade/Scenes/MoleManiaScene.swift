import SpriteKit
import Foundation

final class MoleManiaScene: BaseArcadeScene {
    private var combo = 0
    private var frenzyUntil: TimeInterval = 0
    private var lastMole: TimeInterval = 0

    init(game: GameModel) { super.init(gameID: game.id, title: game.title) }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func startGame() {
        for row in 0..<3 {
            for col in 0..<3 {
                let hole = SKShapeNode(ellipseOf: CGSize(width: 74, height: 34))
                hole.fillColor = .black.withAlphaComponent(0.45)
                hole.strokeColor = .white.withAlphaComponent(0.25)
                hole.position = CGPoint(x: 90 + CGFloat(col) * 104, y: 170 + CGFloat(row) * 112)
                addChild(hole)
            }
        }
        addInstruction("點擊金鼠加分，避開炸彈鼠")
    }

    override func update(_ currentTime: TimeInterval) {
        if currentTime - lastMole > 0.62 {
            lastMole = currentTime
            spawnMole(currentTime: currentTime)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let tapped = nodes(at: point).first { $0.name == "mole" || $0.name == "bombMole" || $0.name == "goldMole" }
        guard let tapped else { return }
        if tapped.name == "bombMole" {
            score = max(0, score - 2)
            combo = 0
            flash("BOOM", color: .systemRed)
        } else {
            combo += 1
            let base = tapped.name == "goldMole" ? 3 : 1
            addScore(base * (frenzyUntil > ProcessInfo.processInfo.systemUptime ? 2 : 1))
            if combo >= 5 {
                frenzyUntil = ProcessInfo.processInfo.systemUptime + 2
                combo = 0
                flash("FRENZY")
            }
        }
        tapped.removeFromParent()
    }

    private func spawnMole(currentTime: TimeInterval) {
        let col = Int.random(in: 0..<3)
        let row = Int.random(in: 0..<3)
        let roll = Int.random(in: 0..<10)
        let node = SKShapeNode(circleOfRadius: 24)
        node.name = roll == 0 ? "bombMole" : (roll <= 2 ? "goldMole" : "mole")
        node.fillColor = roll == 0 ? .systemRed : (roll <= 2 ? .systemYellow : .brown)
        node.strokeColor = .white
        node.position = CGPoint(x: 90 + CGFloat(col) * 104, y: 184 + CGFloat(row) * 112)
        addChild(node)
        node.run(.sequence([.wait(forDuration: 0.72), .fadeOut(withDuration: 0.12), .removeFromParent()]))
    }
}
