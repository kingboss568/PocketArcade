import SpriteKit

final class BubblePopScene: BaseArcadeScene {
    private let colors: [SKColor] = [.systemPink, .systemCyan, .systemYellow, .systemGreen]

    init(game: GameModel) { super.init(gameID: game.id, title: game.title) }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func startGame() {
        for row in 0..<6 {
            for col in 0..<8 {
                addBubble(at: CGPoint(x: 36 + CGFloat(col) * 44, y: size.height - 140 - CGFloat(row) * 38), color: colors[(row + col) % colors.count], name: "target")
            }
        }
        addInstruction("拖曳瞄準，放開發射泡泡")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let target = touches.first?.location(in: self) else { return }
        let bubble = addBubble(at: CGPoint(x: size.width / 2, y: 88), color: colors.randomElement() ?? .systemPink, name: "shot")
        let move = SKAction.move(to: target, duration: 0.45)
        bubble.run(.sequence([move, .run { [weak self, weak bubble] in self?.resolveShot(bubble) }]))
    }

    private func resolveShot(_ shot: SKNode?) {
        guard let shot else { return }
        let hits = children.filter { $0.name == "target" && $0.frame.intersects(shot.frame) }
        hits.prefix(3).forEach { $0.removeFromParent(); addScore(20) }
        shot.removeFromParent()
        if children.contains(where: { $0.name == "target" }) == false {
            level += 1
            flash("BOSS POPPED")
        }
    }

    @discardableResult
    private func addBubble(at point: CGPoint, color: SKColor, name: String) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: 15)
        node.name = name
        node.fillColor = color
        node.strokeColor = .white
        node.position = point
        addChild(node)
        return node
    }
}
