import SpriteKit

final class SnakeEVOScene: BaseArcadeScene {
    private var snake = [CGPoint(x: 9, y: 12), CGPoint(x: 8, y: 12), CGPoint(x: 7, y: 12)]
    private var direction = CGPoint(x: 1, y: 0)
    private var food = CGPoint(x: 13, y: 12)
    private var lastStep: TimeInterval = 0
    private let cell: CGFloat = 18

    init(game: GameModel) { super.init(gameID: game.id, title: game.title) }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func startGame() {
        addInstruction("滑動改變方向，吃食物進化")
        drawBoard()
    }

    override func update(_ currentTime: TimeInterval) {
        guard currentTime - lastStep > 0.16 else { return }
        lastStep = currentTime
        var head = snake[0]
        head.x += direction.x
        head.y += direction.y
        if head.x < 0 || head.x >= 20 || head.y < 0 || head.y >= 26 || snake.contains(head) {
            snake = [CGPoint(x: 9, y: 12), CGPoint(x: 8, y: 12), CGPoint(x: 7, y: 12)]
            direction = CGPoint(x: 1, y: 0)
            flash("GAME OVER", color: .systemRed)
            return
        }
        snake.insert(head, at: 0)
        if head == food {
            addScore(12)
            food = CGPoint(x: Int.random(in: 1..<19), y: Int.random(in: 2..<25))
        } else {
            snake.removeLast()
        }
        drawBoard()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let start = touch.previousLocation(in: self)
        let end = touch.location(in: self)
        let delta = CGPoint(x: end.x - start.x, y: end.y - start.y)
        if abs(delta.x) > abs(delta.y) {
            direction = CGPoint(x: delta.x > 0 ? 1 : -1, y: 0)
        } else {
            direction = CGPoint(x: 0, y: delta.y > 0 ? 1 : -1)
        }
    }

    private func drawBoard() {
        children.filter { $0.name == "snakeCell" || $0.name == "food" }.forEach { $0.removeFromParent() }
        for point in snake {
            addCell(point, color: .systemGreen, name: "snakeCell")
        }
        addCell(food, color: .systemRed, name: "food")
    }

    private func addCell(_ point: CGPoint, color: SKColor, name: String) {
        let node = SKShapeNode(rectOf: CGSize(width: cell - 2, height: cell - 2), cornerRadius: 3)
        node.name = name
        node.fillColor = color
        node.strokeColor = .clear
        node.position = CGPoint(x: 18 + point.x * cell, y: 92 + point.y * cell)
        addChild(node)
    }
}
