import SpriteKit

final class StackAttackScene: BaseArcadeScene {
    private let columns = 10
    private let rows = 18
    private let cell: CGFloat = 24
    private var board: Set<String> = []
    private var block = CGPoint(x: 4, y: 17)
    private var lastDrop: TimeInterval = 0

    init(game: GameModel) { super.init(gameID: game.id, title: game.title) }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func startGame() {
        addInstruction("左右滑移動，下滑加速，點擊旋轉/落子")
        redraw()
    }

    override func update(_ currentTime: TimeInterval) {
        guard currentTime - lastDrop > max(0.18, 0.65 - Double(level) * 0.04) else { return }
        lastDrop = currentTime
        drop()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let start = touch.previousLocation(in: self)
        let end = touch.location(in: self)
        let delta = CGPoint(x: end.x - start.x, y: end.y - start.y)
        if abs(delta.x) > 22 {
            block.x = min(max(0, block.x + (delta.x > 0 ? 1 : -1)), CGFloat(columns - 1))
        } else if delta.y < -20 {
            drop()
        } else {
            addScore(1)
        }
        redraw()
    }

    private func drop() {
        if block.y <= 0 || board.contains(key(x: Int(block.x), y: Int(block.y - 1))) {
            board.insert(key(x: Int(block.x), y: Int(block.y)))
            clearRows()
            block = CGPoint(x: Int.random(in: 0..<columns), y: rows - 1)
            if board.contains(key(x: Int(block.x), y: Int(block.y))) {
                board.removeAll()
                flash("RESCUE CLEAR", color: .systemOrange)
            }
        } else {
            block.y -= 1
        }
        redraw()
    }

    private func clearRows() {
        for row in 0..<rows {
            let filled = (0..<columns).allSatisfy { board.contains(key(x: $0, y: row)) }
            if filled {
                for col in 0..<columns { board.remove(key(x: col, y: row)) }
                addScore(100)
                if score / 500 + 1 > level { level = min(8, score / 500 + 1) }
            }
        }
    }

    private func redraw() {
        children.filter { $0.name == "stack" }.forEach { $0.removeFromParent() }
        for item in board {
            let parts = item.split(separator: ":").compactMap { Int($0) }
            if parts.count == 2 { addBlock(x: parts[0], y: parts[1], color: .systemCyan) }
        }
        addBlock(x: Int(block.x), y: Int(block.y), color: .systemYellow)
    }

    private func addBlock(x: Int, y: Int, color: SKColor) {
        let node = SKShapeNode(rectOf: CGSize(width: cell - 2, height: cell - 2), cornerRadius: 4)
        node.name = "stack"
        node.fillColor = color
        node.strokeColor = .white.withAlphaComponent(0.35)
        node.position = CGPoint(x: 78 + CGFloat(x) * cell, y: 108 + CGFloat(y) * cell)
        addChild(node)
    }

    private func key(x: Int, y: Int) -> String { "\(x):\(y)" }
}
