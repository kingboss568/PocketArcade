import SpriteKit

/// 打地鼠狂熱：60 秒限時、一般鼠/金鼠/炸彈鼠、Combo 連擊、速度漸增。
final class MoleManiaScene: BaseArcadeScene {

    private enum MoleKind { case normal, gold, bomb }

    private struct Hole {
        let position: CGPoint
        var mole: SKLabelNode?
        var kind: MoleKind = .normal
        var whacked = false
    }

    private var holes: [Hole] = []
    private var timeLeft: TimeInterval = 60
    private var timerLabel: SKLabelNode!
    private var timerBar: SKShapeNode!
    private var spawnAccumulator: TimeInterval = 0
    private var spawnInterval: TimeInterval = 1.0
    private var combo = 0
    private var comboLabel: SKLabelNode!

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.16, green: 0.11, blue: 0.06, alpha: 1),
                                    bottom: UIColor(red: 0.07, green: 0.05, blue: 0.03, alpha: 1))
    }

    override func setupGame() {
        let rows = 4
        let cols = 3
        let areaTop = playTop - 90
        let areaBottom = playBottom + 90
        let stepY = (areaTop - areaBottom) / CGFloat(rows - 1)
        let stepX = size.width / CGFloat(cols + 1)

        for row in 0..<rows {
            for col in 0..<cols {
                let position = CGPoint(x: stepX * CGFloat(col + 1), y: areaBottom + stepY * CGFloat(row))
                let dirt = SKShapeNode(ellipseOf: CGSize(width: 86, height: 36))
                dirt.fillColor = SKColor(red: 0.24, green: 0.16, blue: 0.09, alpha: 1)
                dirt.strokeColor = SKColor(red: 0.38, green: 0.26, blue: 0.14, alpha: 1)
                dirt.lineWidth = 3
                dirt.position = position
                gameLayer.addChild(dirt)
                holes.append(Hole(position: position))
            }
        }

        timerLabel = ArcadeFX.label("60", size: 22, color: .systemYellow, font: "AvenirNext-Heavy")
        timerLabel.position = CGPoint(x: size.width / 2, y: playTop - 24)
        timerLabel.zPosition = 100
        gameLayer.addChild(timerLabel)

        timerBar = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width - 60, height: 5), cornerRadius: 2.5)
        timerBar.fillColor = .systemYellow
        timerBar.strokeColor = .clear
        timerBar.position = CGPoint(x: 30, y: playTop - 44)
        timerBar.zPosition = 100
        gameLayer.addChild(timerBar)

        comboLabel = ArcadeFX.label("", size: 16, color: .systemOrange, font: "AvenirNext-Heavy")
        comboLabel.position = CGPoint(x: size.width / 2, y: playBottom + 26)
        comboLabel.zPosition = 100
        gameLayer.addChild(comboLabel)
    }

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        timeLeft -= deltaTime
        if timeLeft <= 0 {
            endGame(message: "時間到！")
            return
        }
        timerLabel.text = "\(Int(ceil(timeLeft)))"
        timerLabel.fontColor = timeLeft < 10 ? .systemRed : .systemYellow
        timerBar.xScale = max(timeLeft / 60, 0)

        spawnAccumulator += deltaTime
        let elapsed = 60 - timeLeft
        spawnInterval = max(1.0 - elapsed * 0.012, 0.42)
        if spawnAccumulator >= spawnInterval {
            spawnAccumulator = 0
            spawnMole()
        }
    }

    private func spawnMole() {
        let freeIndices = holes.indices.filter { holes[$0].mole == nil }
        guard let index = freeIndices.randomElement() else { return }

        let roll = Int.random(in: 0..<10)
        let kind: MoleKind = roll < 7 ? .normal : (roll < 9 ? .gold : .bomb)
        let emoji: String
        switch kind {
        case .normal: emoji = "🐹"
        case .gold: emoji = "🌟"
        case .bomb: emoji = "💣"
        }

        let mole = ArcadeFX.emojiNode(emoji, size: 46)
        mole.position = CGPoint(x: holes[index].position.x, y: holes[index].position.y - 18)
        mole.alpha = 0
        mole.setScale(0.3)
        mole.zPosition = 20
        gameLayer.addChild(mole)
        holes[index].mole = mole
        holes[index].kind = kind
        holes[index].whacked = false

        let upDuration = max(0.85 - (60 - timeLeft) * 0.008, 0.45)
        mole.run(.sequence([
            .group([.fadeIn(withDuration: 0.12), .scale(to: 1, duration: 0.14), .moveBy(x: 0, y: 18, duration: 0.14)]),
            .wait(forDuration: upDuration),
            .group([.fadeOut(withDuration: 0.14), .moveBy(x: 0, y: -18, duration: 0.14)]),
            .removeFromParent()
        ])) { [weak self] in
            guard let self else { return }
            if self.holes[index].whacked == false && kind != .bomb {
                self.combo = 0
                self.comboLabel.text = ""
            }
            self.holes[index].mole = nil
        }
    }

    override func gameTouchBegan(at point: CGPoint) {
        for index in holes.indices {
            guard let mole = holes[index].mole, holes[index].whacked == false else { continue }
            if hypot(mole.position.x - point.x, mole.position.y - point.y) < 46 {
                holes[index].whacked = true
                whack(mole: mole, kind: holes[index].kind, index: index)
                return
            }
        }
    }

    private func whack(mole: SKLabelNode, kind: MoleKind, index: Int) {
        mole.removeAllActions()
        switch kind {
        case .normal:
            combo += 1
            let bonus = min(combo, 5)
            addScore(10 * bonus)
            ArcadeFX.floatingScore("+\(10 * bonus)", at: mole.position, in: gameLayer, color: .white, fontSize: 16)
            ArcadeFX.burst(in: gameLayer, at: mole.position, color: .systemOrange, count: 10, speed: 80)
            ArcadeFX.Haptic.medium()
        case .gold:
            combo += 1
            addScore(50)
            ArcadeFX.floatingScore("+50", at: mole.position, in: gameLayer, color: .systemYellow, fontSize: 19)
            ArcadeFX.burst(in: gameLayer, at: mole.position, color: .systemYellow, count: 20)
            ArcadeFX.Haptic.success()
        case .bomb:
            combo = 0
            addScore(-30)
            timeLeft = max(timeLeft - 5, 1)
            flash("💥 -30 分 -5 秒", color: .systemRed, fontSize: 24)
            ArcadeFX.burst(in: gameLayer, at: mole.position, color: .systemRed, count: 26, speed: 180)
            ArcadeFX.Haptic.error()
        }
        comboLabel.text = combo >= 2 ? "COMBO ×\(min(combo, 5))" : ""
        if combo > 0, combo % 10 == 0 { level += 1 }
        mole.run(.sequence([
            .group([.scale(to: 1.4, duration: 0.07), .fadeOut(withDuration: 0.12)]),
            .removeFromParent()
        ])) { [weak self] in
            self?.holes[index].mole = nil
        }
    }
}
