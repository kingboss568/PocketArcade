import SpriteKit

final class TwentyFortyEightScene: BaseArcadeScene {
    private var engine = TwentyFortyEightEngine()
    private let cell: CGFloat = 70

    init(game: GameModel) { super.init(gameID: game.id, title: game.title) }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func startGame() {
        addInstruction("滑動合併數字，挑戰 4096 / 8192")
        drawBoard()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let start = touch.previousLocation(in: self)
        let end = touch.location(in: self)
        let delta = CGPoint(x: end.x - start.x, y: end.y - start.y)
        let direction: MoveDirection
        if abs(delta.x) > abs(delta.y) {
            direction = delta.x > 0 ? .right : .left
        } else {
            direction = delta.y > 0 ? .up : .down
        }
        if engine.move(direction) {
            score = engine.score
            if engine.hasWon { flash("2048!") }
            drawBoard()
        }
    }

    private func drawBoard() {
        children.filter { $0.name == "tile" }.forEach { $0.removeFromParent() }
        for index in 0..<16 {
            let row = index / 4
            let col = index % 4
            let value = engine.board[index]
            let x = 75 + CGFloat(col) * cell
            let y = 180 + CGFloat(3 - row) * cell
            let tile = SKShapeNode(rectOf: CGSize(width: cell - 8, height: cell - 8), cornerRadius: 10)
            tile.name = "tile"
            tile.fillColor = color(for: value)
            tile.strokeColor = .white.withAlphaComponent(0.25)
            tile.position = CGPoint(x: x, y: y)
            addChild(tile)
            if value > 0 {
                let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
                label.name = "tile"
                label.text = "\(value)"
                label.fontSize = value < 1024 ? 22 : 16
                label.fontColor = .black
                label.verticalAlignmentMode = .center
                label.position = tile.position
                addChild(label)
            }
        }
    }

    private func color(for value: Int) -> SKColor {
        switch value {
        case 0: return .white.withAlphaComponent(0.12)
        case 2: return .systemYellow
        case 4: return .systemOrange
        case 8: return .systemPink
        case 16: return .systemRed
        case 32: return .systemPurple
        case 64: return .systemBlue
        default: return .systemCyan
        }
    }
}
