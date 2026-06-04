import SpriteKit

final class GomokuGoScene: BaseArcadeScene {
    private var rules = GomokuRuleService(size: 15)
    private var currentStone: GomokuStone = .black
    private let boardOrigin = CGPoint(x: 28, y: 142)
    private let gap: CGFloat = 24

    init(game: GameModel) { super.init(gameID: game.id, title: game.title) }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func startGame() {
        drawBoard()
        addInstruction("點擊棋盤落子，五子連線獲勝")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let column = Int(round((point.x - boardOrigin.x) / gap))
        let row = Int(round((point.y - boardOrigin.y) / gap))
        guard rules.place(currentStone, row: row, column: column) else { return }
        addScore(1)
        drawStone(row: row, column: column, stone: currentStone)
        if let winner = rules.winner(after: row, column: column) {
            flash(winner == .black ? "BLACK WINS" : "WHITE WINS")
            addScore(200)
            rules = GomokuRuleService(size: 15)
            children.filter { $0.name == "stone" }.forEach { $0.removeFromParent() }
        }
        currentStone = currentStone == .black ? .white : .black
    }

    private func drawBoard() {
        for index in 0..<15 {
            let h = SKShapeNode(rect: CGRect(x: boardOrigin.x, y: boardOrigin.y + CGFloat(index) * gap, width: gap * 14, height: 1))
            h.strokeColor = .white.withAlphaComponent(0.32)
            addChild(h)
            let v = SKShapeNode(rect: CGRect(x: boardOrigin.x + CGFloat(index) * gap, y: boardOrigin.y, width: 1, height: gap * 14))
            v.strokeColor = .white.withAlphaComponent(0.32)
            addChild(v)
        }
    }

    private func drawStone(row: Int, column: Int, stone: GomokuStone) {
        let node = SKShapeNode(circleOfRadius: 9)
        node.name = "stone"
        node.fillColor = stone == .black ? .black : .white
        node.strokeColor = stone == .black ? .white : .black
        node.position = CGPoint(x: boardOrigin.x + CGFloat(column) * gap, y: boardOrigin.y + CGFloat(row) * gap)
        addChild(node)
    }
}
