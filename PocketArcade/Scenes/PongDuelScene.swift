import SpriteKit

/// 乒乓對戰：拖曳下方球拍 vs AI，先得 7 分獲勝，球速與 AI 隨勝場提升。
final class PongDuelScene: BaseArcadeScene {

    private var playerPaddle: SKShapeNode!
    private var aiPaddle: SKShapeNode!
    private var ball: SKNode!
    private var ballVelocity = CGVector.zero
    private var paddleTargetX: CGFloat = 0
    private var playerScore = 0
    private var aiScore = 0
    private var scoreboard: SKLabelNode!
    private var serving = true
    private var rally = 0
    private let paddleSize = CGSize(width: 92, height: 14)
    private var baseSpeed: CGFloat { 360 + CGFloat(level - 1) * 40 }
    private var aiSpeed: CGFloat { 230 + CGFloat(level - 1) * 55 }

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.04, green: 0.12, blue: 0.14, alpha: 1),
                                    bottom: UIColor(red: 0.02, green: 0.05, blue: 0.07, alpha: 1))
    }

    override func setupGame() {
        paddleTargetX = size.width / 2
        let midY = (playTop + playBottom) / 2

        // 中線
        let dashes = SKShapeNode()
        let path = CGMutablePath()
        var x: CGFloat = 10
        while x < size.width - 10 {
            path.move(to: CGPoint(x: x, y: midY))
            path.addLine(to: CGPoint(x: x + 12, y: midY))
            x += 26
        }
        dashes.path = path
        dashes.strokeColor = .white.withAlphaComponent(0.25)
        dashes.lineWidth = 2
        gameLayer.addChild(dashes)

        playerPaddle = makePaddle(color: accent)
        playerPaddle.position = CGPoint(x: size.width / 2, y: playBottom + 50)
        gameLayer.addChild(playerPaddle)

        aiPaddle = makePaddle(color: .systemPink)
        aiPaddle.position = CGPoint(x: size.width / 2, y: playTop - 50)
        gameLayer.addChild(aiPaddle)

        ball = ArcadeFX.glowDot(radius: 9, color: .white)
        ball.position = CGPoint(x: size.width / 2, y: midY)
        let trail = ArcadeFX.trailEmitter(color: .cyan, birthRate: 70, lifetime: 0.35, scale: 0.18)
        ball.addChild(trail)
        gameLayer.addChild(ball)

        scoreboard = ArcadeFX.label("0 : 0", size: 30, color: .white.withAlphaComponent(0.85), font: "AvenirNext-Heavy")
        scoreboard.position = CGPoint(x: size.width - 52, y: midY)
        scoreboard.zPosition = 100
        gameLayer.addChild(scoreboard)
    }

    private func makePaddle(color: SKColor) -> SKShapeNode {
        let paddle = SKShapeNode(rectOf: paddleSize, cornerRadius: 7)
        paddle.fillColor = color
        paddle.strokeColor = .white.withAlphaComponent(0.8)
        paddle.lineWidth = 1.5
        paddle.glowWidth = 4
        return paddle
    }

    override func gameDidStart() { serve(towardPlayer: Bool.random()) }

    private func serve(towardPlayer: Bool) {
        serving = true
        rally = 0
        ball.position = CGPoint(x: size.width / 2, y: (playTop + playBottom) / 2)
        ballVelocity = .zero
        run(.sequence([.wait(forDuration: 0.7), .run { [weak self] in
            guard let self else { return }
            let angle = CGFloat.random(in: (.pi * 0.30)...(.pi * 0.70))
            let dy = towardPlayer ? -sin(angle) : sin(angle)
            self.ballVelocity = CGVector(dx: cos(angle) * self.baseSpeed * (Bool.random() ? 1 : -1), dy: dy * self.baseSpeed)
            self.serving = false
        }]))
    }

    override func gameTouchBegan(at point: CGPoint) { paddleTargetX = point.x }
    override func gameTouchMoved(to point: CGPoint, previous: CGPoint) { paddleTargetX = point.x }

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        let dt = CGFloat(deltaTime)
        let halfPaddle = paddleSize.width / 2

        // 玩家球拍
        let clamped = min(max(paddleTargetX, halfPaddle + 6), size.width - halfPaddle - 6)
        playerPaddle.position.x += (clamped - playerPaddle.position.x) * min(1, dt * 20)

        // AI 球拍：預測球的 x，帶一點誤差
        let aiTarget = ballVelocity.dy > 0 ? ball.position.x : size.width / 2
        let aiDelta = aiTarget - aiPaddle.position.x
        let maxStep = aiSpeed * dt
        aiPaddle.position.x += min(max(aiDelta, -maxStep), maxStep)
        aiPaddle.position.x = min(max(aiPaddle.position.x, halfPaddle + 6), size.width - halfPaddle - 6)

        guard serving == false else { return }
        var pos = ball.position
        pos.x += ballVelocity.dx * dt
        pos.y += ballVelocity.dy * dt

        // 側牆
        if pos.x < 11 { pos.x = 11; ballVelocity.dx = abs(ballVelocity.dx); ArcadeFX.Haptic.light() }
        if pos.x > size.width - 11 { pos.x = size.width - 11; ballVelocity.dx = -abs(ballVelocity.dx); ArcadeFX.Haptic.light() }

        // 玩家球拍
        if ballVelocity.dy < 0,
           abs(pos.y - playerPaddle.position.y) < 16,
           abs(pos.x - playerPaddle.position.x) < halfPaddle + 10 {
            bounce(off: playerPaddle, position: &pos, upward: true)
        }
        // AI 球拍
        if ballVelocity.dy > 0,
           abs(pos.y - aiPaddle.position.y) < 16,
           abs(pos.x - aiPaddle.position.x) < halfPaddle + 10 {
            bounce(off: aiPaddle, position: &pos, upward: false)
        }

        // 得分
        if pos.y < playBottom - 14 {
            aiScore += 1
            pointScored(playerWon: false)
            return
        }
        if pos.y > playTop + 14 {
            playerScore += 1
            addScore(20 + rally * 2)
            pointScored(playerWon: true)
            return
        }

        ball.position = pos
    }

    private func bounce(off paddle: SKShapeNode, position: inout CGPoint, upward: Bool) {
        let halfPaddle = paddleSize.width / 2
        let offset = (position.x - paddle.position.x) / halfPaddle
        let angle = CGFloat.pi / 2 - offset * (.pi * 0.34)
        rally += 1
        let speed = min(baseSpeed + CGFloat(rally) * 14, 760)
        ballVelocity = CGVector(dx: cos(angle) * speed, dy: (upward ? 1 : -1) * abs(sin(angle)) * speed)
        position.y = paddle.position.y + (upward ? 17 : -17)
        ArcadeFX.burst(in: gameLayer, at: position, color: UIColor(cgColor: paddle.fillColor.cgColor), count: 6, speed: 50)
        ArcadeFX.Haptic.medium()
    }

    private func pointScored(playerWon: Bool) {
        scoreboard.text = "\(playerScore) : \(aiScore)"
        ArcadeFX.burst(in: gameLayer, at: ball.position, color: playerWon ? .systemGreen : .systemRed, count: 18)
        if playerWon { ArcadeFX.Haptic.success() } else { ArcadeFX.Haptic.error() }

        if playerScore >= 7 {
            level += 1
            addScore(100)
            playerScore = 0
            aiScore = 0
            flash("獲勝！AI 升級為 LV \(level)", color: accent, fontSize: 24)
            scoreboard.text = "0 : 0"
            serve(towardPlayer: false)
        } else if aiScore >= 7 {
            endGame(message: "AI 獲勝")
        } else {
            flash(playerWon ? "得分！" : "失分", color: playerWon ? .systemGreen : .systemRed, fontSize: 24)
            serve(towardPlayer: playerWon == false)
        }
    }
}
