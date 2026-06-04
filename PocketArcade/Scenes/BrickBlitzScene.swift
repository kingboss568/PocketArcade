import SpriteKit

final class BrickBlitzScene: BaseArcadeScene {
    private let paddle = SKShapeNode(rectOf: CGSize(width: 86, height: 14), cornerRadius: 7)
    private let ball = SKShapeNode(circleOfRadius: 9)
    private var velocity = CGVector(dx: 155, dy: 220)
    private var brickCount = 0
    private var cleared = 0

    init(game: GameModel) {
        super.init(gameID: game.id, title: game.title)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func startGame() {
        paddle.fillColor = .systemPink
        paddle.strokeColor = .white
        paddle.position = CGPoint(x: size.width / 2, y: 90)
        addChild(paddle)

        ball.fillColor = .systemYellow
        ball.strokeColor = .clear
        ball.position = CGPoint(x: size.width / 2, y: 126)
        addChild(ball)

        for row in 0..<5 {
            for col in 0..<7 {
                let brick = SKShapeNode(rectOf: CGSize(width: 44, height: 18), cornerRadius: 4)
                brick.name = row == 0 ? "goldBrick" : "brick"
                brick.fillColor = row == 0 ? .systemYellow : (row.isMultiple(of: 2) ? .systemRed : .systemCyan)
                brick.strokeColor = .white.withAlphaComponent(0.55)
                brick.position = CGPoint(x: 42 + CGFloat(col) * 50, y: size.height - 132 - CGFloat(row) * 28)
                addChild(brick)
                brickCount += 1
            }
        }
        addInstruction("拖曳球拍，點一下可加速彈球")
    }

    override func update(_ currentTime: TimeInterval) {
        let dt: CGFloat = 1.0 / 60.0
        ball.position.x += velocity.dx * dt
        ball.position.y += velocity.dy * dt
        if ball.position.x < 12 || ball.position.x > size.width - 12 { velocity.dx *= -1 }
        if ball.position.y > size.height - 94 { velocity.dy *= -1 }
        if ball.frame.intersects(paddle.frame), velocity.dy < 0 { velocity.dy = abs(velocity.dy) }
        if ball.position.y < 42 {
            ball.position = CGPoint(x: size.width / 2, y: 130)
            velocity = CGVector(dx: 150, dy: 220)
            flash("TRY AGAIN", color: .systemPink)
        }
        for node in children where node.name?.contains("brick") == true || node.name == "goldBrick" {
            if ball.frame.intersects(node.frame) {
                node.removeFromParent()
                cleared += 1
                addScore(node.name == "goldBrick" ? 30 : 10)
                velocity.dy *= -1
                if Double(cleared) / Double(max(brickCount, 1)) >= 0.8 {
                    level += 1
                    flash("LEVEL CLEAR")
                    cleared = 0
                }
                break
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        paddle.position.x = min(max(location.x, 48), size.width - 48)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        velocity.dx *= 1.05
        velocity.dy *= 1.12
    }
}
