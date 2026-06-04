import SpriteKit

class BaseArcadeScene: SKScene {
    let gameID: ArcadeGameID
    let displayTitle: String
    var onScoreChanged: ((Int) -> Void)?
    var onLevelChanged: ((Int) -> Void)?

    var score: Int = 0 {
        didSet {
            scoreLabel.text = "SCORE \(score)"
            onScoreChanged?(score)
        }
    }

    var level: Int = 1 {
        didSet {
            levelLabel.text = "LV \(level)"
            onLevelChanged?(level)
        }
    }

    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private var started = false

    init(gameID: ArcadeGameID, title: String) {
        self.gameID = gameID
        self.displayTitle = title
        super.init(size: CGSize(width: 390, height: 720))
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        guard started == false else { return }
        started = true
        addBackdrop()
        addHUD()
        startGame()
    }

    func startGame() {}

    func addInstruction(_ text: String) {
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = text
        label.fontSize = 13
        label.fontColor = .white.withAlphaComponent(0.72)
        label.position = CGPoint(x: size.width / 2, y: 34)
        addChild(label)
    }

    func flash(_ text: String, color: SKColor = .systemYellow) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 28
        label.fontColor = color
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 50
        addChild(label)
        label.run(.sequence([.scale(to: 1.25, duration: 0.18), .fadeOut(withDuration: 0.55), .removeFromParent()]))
    }

    func addScore(_ amount: Int) {
        score += amount
    }

    private func addHUD() {
        titleLabel.text = displayTitle
        titleLabel.fontSize = 18
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 44)
        titleLabel.zPosition = 10
        addChild(titleLabel)

        scoreLabel.text = "SCORE 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.fontSize = 13
        scoreLabel.fontColor = .systemYellow
        scoreLabel.position = CGPoint(x: 18, y: size.height - 76)
        scoreLabel.zPosition = 10
        addChild(scoreLabel)

        levelLabel.text = "LV 1"
        levelLabel.horizontalAlignmentMode = .right
        levelLabel.fontSize = 13
        levelLabel.fontColor = .systemCyan
        levelLabel.position = CGPoint(x: size.width - 18, y: size.height - 76)
        levelLabel.zPosition = 10
        addChild(levelLabel)
    }

    private func addBackdrop() {
        for index in 0..<12 {
            let line = SKShapeNode(rectOf: CGSize(width: size.width * 1.8, height: 1))
            line.strokeColor = SKColor.systemPink.withAlphaComponent(0.08)
            line.position = CGPoint(x: size.width / 2, y: CGFloat(index) * 58 + 20)
            addChild(line)
        }
    }
}
