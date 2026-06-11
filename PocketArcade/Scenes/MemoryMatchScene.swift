import SpriteKit

/// 記憶翻牌：翻開兩張相同圖案配對，連續配對 Combo，過關後牌數增加。
final class MemoryMatchScene: BaseArcadeScene {

    private struct Card {
        let node: SKNode
        let face: SKLabelNode
        let back: SKShapeNode
        let emoji: String
        var isFaceUp = false
        var isMatched = false
    }

    private var cards: [Card] = []
    private var firstPick: Int?
    private var locked = false
    private var combo = 0
    private var movesLabel: SKLabelNode!
    private var moves = 0
    private let emojiPool = ["🍎", "🍌", "🍇", "🍓", "🍊", "🍉", "🥝", "🍒", "🥥", "🍍",
                             "🐶", "🐱", "🐼", "🦊", "🐸", "🦁", "🐯", "🐨", "🐷", "🐵"]

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.10, green: 0.10, blue: 0.24, alpha: 1),
                                    bottom: UIColor(red: 0.04, green: 0.04, blue: 0.10, alpha: 1))
        ArcadeFX.addStarfield(to: self, count: 24)
    }

    override func setupGame() {
        movesLabel = ArcadeFX.label("步數 0", size: 15, color: .white.withAlphaComponent(0.8), font: "AvenirNext-Bold")
        movesLabel.position = CGPoint(x: size.width / 2, y: playBottom + 14)
        movesLabel.zPosition = 100
        gameLayer.addChild(movesLabel)
        dealCards()
    }

    private func gridConfig() -> (cols: Int, rows: Int) {
        switch level {
        case 1: return (3, 4)
        case 2: return (4, 4)
        case 3: return (4, 5)
        case 4: return (4, 6)
        default: return (5, 6)
        }
    }

    private func dealCards() {
        cards.forEach { $0.node.removeFromParent() }
        cards.removeAll()
        firstPick = nil
        locked = false
        combo = 0
        moves = 0
        movesLabel.text = "步數 0"

        let (cols, rows) = gridConfig()
        let pairCount = cols * rows / 2
        var faces = Array(emojiPool.shuffled().prefix(pairCount))
        faces += faces
        faces.shuffle()

        let margin: CGFloat = 18
        let spacing: CGFloat = 10
        let cardWidth = (size.width - margin * 2 - spacing * CGFloat(cols - 1)) / CGFloat(cols)
        let cardHeight = min(cardWidth * 1.25, (playTop - playBottom - 60 - spacing * CGFloat(rows - 1)) / CGFloat(rows))
        let totalHeight = cardHeight * CGFloat(rows) + spacing * CGFloat(rows - 1)
        let startY = (playTop + playBottom + 30) / 2 + totalHeight / 2 - cardHeight / 2

        for row in 0..<rows {
            for col in 0..<cols {
                let index = row * cols + col
                let emoji = faces[index]
                let container = SKNode()
                container.position = CGPoint(
                    x: margin + cardWidth / 2 + CGFloat(col) * (cardWidth + spacing),
                    y: startY - CGFloat(row) * (cardHeight + spacing)
                )
                container.zPosition = 10

                let back = ArcadeFX.roundedRect(size: CGSize(width: cardWidth, height: cardHeight), radius: 9,
                                                fill: accent.withAlphaComponent(0.85),
                                                stroke: .white.withAlphaComponent(0.7), lineWidth: 1.5)
                let pattern = ArcadeFX.label("?", size: cardWidth * 0.4, color: .white.withAlphaComponent(0.85), font: "AvenirNext-Heavy")
                back.addChild(pattern)
                container.addChild(back)

                let face = ArcadeFX.emojiNode(emoji, size: cardWidth * 0.62)
                face.alpha = 0
                let faceBG = ArcadeFX.roundedRect(size: CGSize(width: cardWidth, height: cardHeight), radius: 9,
                                                  fill: SKColor.white.withAlphaComponent(0.92))
                faceBG.zPosition = -1
                face.addChild(faceBG)
                container.addChild(face)

                // 發牌動畫
                container.setScale(0)
                container.run(.sequence([.wait(forDuration: Double(index) * 0.03), .scale(to: 1, duration: 0.18)]))

                gameLayer.addChild(container)
                cards.append(Card(node: container, face: face, back: back, emoji: emoji))
            }
        }
    }

    override func gameTouchBegan(at point: CGPoint) {
        guard locked == false else { return }
        guard let index = cards.firstIndex(where: { card in
            card.isMatched == false && card.isFaceUp == false && card.node.calculateAccumulatedFrame().contains(point)
        }) else { return }
        flip(index: index, faceUp: true)

        if let first = firstPick {
            moves += 1
            movesLabel.text = "步數 \(moves)"
            locked = true
            if cards[first].emoji == cards[index].emoji {
                // 配對成功
                combo += 1
                let points = 20 * min(combo, 5)
                cards[first].isMatched = true
                cards[index].isMatched = true
                firstPick = nil
                addScore(points)
                let midPoint = CGPoint(
                    x: (cards[first].node.position.x + cards[index].node.position.x) / 2,
                    y: (cards[first].node.position.y + cards[index].node.position.y) / 2
                )
                ArcadeFX.floatingScore(combo >= 2 ? "COMBO +\(points)" : "+\(points)", at: midPoint, in: gameLayer, color: .systemYellow, fontSize: 17)
                ArcadeFX.Haptic.success()
                for cardIndex in [first, index] {
                    cards[cardIndex].node.run(.sequence([
                        .scale(to: 1.12, duration: 0.12),
                        .scale(to: 1, duration: 0.12),
                        .fadeAlpha(to: 0.45, duration: 0.2)
                    ]))
                }
                locked = false
                checkComplete()
            } else {
                combo = 0
                firstPick = nil
                ArcadeFX.Haptic.light()
                run(.sequence([.wait(forDuration: 0.75), .run { [weak self] in
                    guard let self else { return }
                    self.flip(index: first, faceUp: false)
                    self.flip(index: index, faceUp: false)
                    self.locked = false
                }]))
            }
        } else {
            firstPick = index
            ArcadeFX.Haptic.light()
        }
    }

    private func flip(index: Int, faceUp: Bool) {
        var card = cards[index]
        card.isFaceUp = faceUp
        cards[index] = card
        let node = card.node
        let half1 = SKAction.scaleX(to: 0, duration: 0.10)
        half1.timingMode = .easeIn
        let half2 = SKAction.scaleX(to: 1, duration: 0.10)
        half2.timingMode = .easeOut
        node.run(.sequence([
            half1,
            .run { card.face.alpha = faceUp ? 1 : 0; card.back.alpha = faceUp ? 0 : 1 },
            half2
        ]))
    }

    private func checkComplete() {
        guard cards.allSatisfy({ $0.isMatched }) else { return }
        let (cols, rows) = gridConfig()
        let pairCount = cols * rows / 2
        let efficiency = max(pairCount * 3 - moves, 0)
        let bonus = 100 + efficiency * 10
        addScore(bonus)
        flash("過關！+\(bonus)", color: accent)
        ArcadeFX.Haptic.success()
        level += 1
        run(.sequence([.wait(forDuration: 1.2), .run { [weak self] in self?.dealCards() }]))
    }
}
