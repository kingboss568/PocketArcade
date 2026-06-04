import SpriteKit

final class PinballProScene: BaseArcadeScene {
    private let ball = SKShapeNode(circleOfRadius: 10)
    private let leftFlipper = SKShapeNode(rectOf: CGSize(width: 76, height: 12), cornerRadius: 6)
    private let rightFlipper = SKShapeNode(rectOf: CGSize(width: 76, height: 12), cornerRadius: 6)
    private var velocity = CGVector(dx: 120, dy: 210)

    init(game: GameModel) { super.init(gameID: game.id, title: game.title) }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func startGame() {
        ball.fillColor = .systemYellow
        ball.strokeColor = .white
        ball.position = CGPoint(x: size.width / 2, y: 240)
        addChild(ball)

        leftFlipper.fillColor = .systemPink
        rightFlipper.fillColor = .systemCyan
        leftFlipper.position = CGPoint(x: 128, y: 112)
        rightFlipper.position = CGPoint(x: 262, y: 112)
        leftFlipper.zRotation = -0.25
        rightFlipper.zRotation = 0.25
        addChild(leftFlipper)
        addChild(rightFlipper)

        for index in 0..<5 {
            let bumper = SKShapeNode(circleOfRadius: 23)
            bumper.name = "bumper"
            bumper.fillColor = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple][index]
            bumper.strokeColor = .white
            bumper.position = CGPoint(x: 78 + CGFloat(index % 3) * 116, y: 310 + CGFloat(index / 3) * 100)
            addChild(bumper)
        }
        addInstruction("點左/右半螢幕控制撥桿")
    }

    override func update(_ currentTime: TimeInterval) {
        let dt: CGFloat = 1 / 60
        ball.position.x += velocity.dx * dt
        ball.position.y += velocity.dy * dt
        velocity.dy -= 2.5
        if ball.position.x < 18 || ball.position.x > size.width - 18 { velocity.dx *= -1 }
        if ball.position.y > size.height - 92 { velocity.dy *= -1 }
        if ball.frame.intersects(leftFlipper.frame) || ball.frame.intersects(rightFlipper.frame) {
            velocity.dy = abs(velocity.dy) + 120
            addScore(5)
        }
        for bumper in children where bumper.name == "bumper" && bumper.frame.intersects(ball.frame) {
            velocity.dx *= -1.05
            velocity.dy = abs(velocity.dy) + 90
            addScore(50)
            bumper.run(.sequence([.scale(to: 1.22, duration: 0.08), .scale(to: 1, duration: 0.12)]))
        }
        if ball.position.y < 48 {
            ball.position = CGPoint(x: size.width / 2, y: 240)
            velocity = CGVector(dx: 120, dy: 230)
            flash("EXTRA BALL", color: .systemCyan)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let x = touches.first?.location(in: self).x else { return }
        let flipper = x < size.width / 2 ? leftFlipper : rightFlipper
        let angle: CGFloat = x < size.width / 2 ? 0.45 : -0.45
        flipper.run(.sequence([.rotate(toAngle: angle, duration: 0.06), .rotate(toAngle: x < size.width / 2 ? -0.25 : 0.25, duration: 0.16)]))
    }
}
