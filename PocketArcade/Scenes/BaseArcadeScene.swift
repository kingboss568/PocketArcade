import SpriteKit
import UIKit

enum ArcadePhase {
    case ready
    case playing
    case paused
    case gameOver
}

/// 所有街機場景的基底：場景內 HUD（不擋觸控）、開始/暫停/結束覆蓋層、觸控路由、分數管理。
class BaseArcadeScene: SKScene {

    // MARK: - Public state

    let gameID: ArcadeGameID
    let game: GameModel
    var accent: SKColor { ArcadeFX.accent(for: gameID) }

    var onScoreChanged: ((Int) -> Void)?
    var onLevelChanged: ((Int) -> Void)?
    var onGameOver: ((Int, Int) -> Void)?
    var onExit: (() -> Void)?
    var onRestart: (() -> Void)?
    var onRequestCoach: (() -> Void)?

    private(set) var phase: ArcadePhase = .ready

    var score: Int = 0 {
        didSet {
            scoreLabel.text = "\(score)"
            onScoreChanged?(score)
        }
    }

    var level: Int = 1 {
        didSet {
            levelLabel.text = "LV \(level)"
            onLevelChanged?(level)
        }
    }

    var bestScore: Int {
        UserDefaults.standard.integer(forKey: gameID.userDefaultsHighScoreKey)
    }

    /// 遊戲內容全部加進這層，暫停時凍結。
    let gameLayer = SKNode()

    /// 安全區
    private(set) var topInset: CGFloat = 59
    private(set) var bottomInset: CGFloat = 34

    /// 遊戲可用區域（HUD 之下）
    var playTop: CGFloat { size.height - topInset - 52 }
    var playBottom: CGFloat { bottomInset + 10 }

    // MARK: - Private nodes

    private let hudLayer = SKNode()
    private let overlayLayer = SKNode()
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let bestLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var lastUpdateTime: TimeInterval = 0
    private var started = false

    // MARK: - Init

    init(game: GameModel) {
        self.game = game
        self.gameID = game.id
        super.init(size: CGSize(width: 390, height: 844))
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.11, alpha: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        guard started == false else { return }
        started = true
        topInset = max(view.safeAreaInsets.top, 47)
        bottomInset = max(view.safeAreaInsets.bottom, 20)

        gameLayer.zPosition = 0
        addChild(gameLayer)
        hudLayer.zPosition = 500
        addChild(hudLayer)
        overlayLayer.zPosition = 900
        addChild(overlayLayer)

        setupBackground()
        setupHUD()
        setupGame()
        showReadyOverlay()
    }

    /// 子類別覆寫：建立背景。預設深色漸層。
    func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.09, green: 0.07, blue: 0.20, alpha: 1),
                                    bottom: UIColor(red: 0.03, green: 0.03, blue: 0.08, alpha: 1))
        ArcadeFX.addStarfield(to: self, count: 36)
    }

    /// 子類別覆寫：建立遊戲內容（加進 gameLayer）。
    func setupGame() {}

    /// 子類別覆寫：玩家點擊開始後呼叫。
    func gameDidStart() {}

    /// 子類別覆寫：每幀更新（只在 playing 時呼叫）。
    func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {}

    /// 子類別覆寫：觸控（只在 playing 時轉送，HUD 按鈕已被攔截）。
    func gameTouchBegan(at point: CGPoint) {}
    func gameTouchMoved(to point: CGPoint, previous: CGPoint) {}
    func gameTouchEnded(at point: CGPoint) {}

    // MARK: - HUD

    private func setupHUD() {
        let barY = size.height - topInset - 26

        let exitButton = ArcadeFX.circleButton(symbol: "✕", name: "btn_exit")
        exitButton.position = CGPoint(x: 34, y: barY)
        hudLayer.addChild(exitButton)

        let pauseButton = ArcadeFX.circleButton(symbol: "II", name: "btn_pause")
        pauseButton.position = CGPoint(x: size.width - 34, y: barY)
        hudLayer.addChild(pauseButton)

        let titleLabel = ArcadeFX.label(game.title, size: 13, color: .white.withAlphaComponent(0.65), font: "AvenirNext-DemiBold")
        titleLabel.position = CGPoint(x: size.width / 2, y: barY + 16)
        hudLayer.addChild(titleLabel)

        scoreLabel.text = "0"
        scoreLabel.fontSize = 26
        scoreLabel.fontColor = .white
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: size.width / 2, y: barY - 7)
        hudLayer.addChild(scoreLabel)

        bestLabel.text = "BEST \(bestScore)"
        bestLabel.fontSize = 11
        bestLabel.fontColor = accent.withAlphaComponent(0.9)
        bestLabel.verticalAlignmentMode = .center
        bestLabel.position = CGPoint(x: size.width / 2, y: barY - 26)
        hudLayer.addChild(bestLabel)

        levelLabel.text = "LV 1"
        levelLabel.fontSize = 12
        levelLabel.fontColor = .white.withAlphaComponent(0.75)
        levelLabel.verticalAlignmentMode = .center
        levelLabel.position = CGPoint(x: size.width - 34, y: barY - 32)
        hudLayer.addChild(levelLabel)

        // HUD 純顯示，不攔截觸控（按鈕由 touchesBegan 命名比對處理）
        hudLayer.isUserInteractionEnabled = false
    }

    // MARK: - Overlays

    private func dimPanel() -> SKSpriteNode {
        let dim = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.72), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dim.name = "overlay_dim"
        return dim
    }

    private func showReadyOverlay() {
        phase = .ready
        gameLayer.isPaused = true
        physicsWorld.speed = 0
        overlayLayer.removeAllChildren()
        overlayLayer.addChild(dimPanel())

        let centerX = size.width / 2
        var y = size.height * 0.66

        let title = ArcadeFX.label(game.title, size: 38, color: .white, font: "AvenirNext-Heavy")
        title.position = CGPoint(x: centerX, y: y)
        overlayLayer.addChild(title)
        y -= 34

        let subtitle = ArcadeFX.label(game.englishTitle.uppercased(), size: 15, color: accent, font: "AvenirNext-DemiBold")
        subtitle.position = CGPoint(x: centerX, y: y)
        overlayLayer.addChild(subtitle)
        y -= 56

        for line in game.mechanics.prefix(4) {
            let tip = ArcadeFX.label("· \(line)", size: 14, color: .white.withAlphaComponent(0.8), font: "AvenirNext-Medium")
            tip.position = CGPoint(x: centerX, y: y)
            overlayLayer.addChild(tip)
            y -= 26
        }

        let start = ArcadeFX.label("點擊任意處開始", size: 19, color: .white, font: "AvenirNext-Heavy")
        start.position = CGPoint(x: centerX, y: size.height * 0.24)
        start.run(.repeatForever(.sequence([.fadeAlpha(to: 0.35, duration: 0.7), .fadeAlpha(to: 1, duration: 0.7)])))
        overlayLayer.addChild(start)
    }

    private func showPauseOverlay() {
        overlayLayer.removeAllChildren()
        overlayLayer.addChild(dimPanel())
        let centerX = size.width / 2

        let title = ArcadeFX.label("暫停", size: 34, color: .white, font: "AvenirNext-Heavy")
        title.position = CGPoint(x: centerX, y: size.height * 0.64)
        overlayLayer.addChild(title)

        let resume = ArcadeFX.pillButton("繼續遊戲", name: "btn_resume", color: accent)
        resume.position = CGPoint(x: centerX, y: size.height * 0.50)
        overlayLayer.addChild(resume)

        let restart = ArcadeFX.pillButton("重新開始", name: "btn_restart", color: SKColor.white.withAlphaComponent(0.18))
        restart.position = CGPoint(x: centerX, y: size.height * 0.41)
        overlayLayer.addChild(restart)

        let coach = ArcadeFX.pillButton("Arcade Coach 提示", name: "btn_coach", color: SKColor.white.withAlphaComponent(0.18))
        coach.position = CGPoint(x: centerX, y: size.height * 0.32)
        overlayLayer.addChild(coach)

        let exit = ArcadeFX.pillButton("離開遊戲", name: "btn_exit", color: SKColor.white.withAlphaComponent(0.18))
        exit.position = CGPoint(x: centerX, y: size.height * 0.23)
        overlayLayer.addChild(exit)
    }

    /// 結束遊戲（子類別呼叫）。
    func endGame(message: String = "GAME OVER") {
        guard phase == .playing || phase == .paused else { return }
        phase = .gameOver
        gameLayer.isPaused = true
        physicsWorld.speed = 0

        let isRecord = score > bestScore
        if isRecord {
            UserDefaults.standard.set(score, forKey: gameID.userDefaultsHighScoreKey)
            ArcadeFX.Haptic.success()
        } else {
            ArcadeFX.Haptic.warning()
        }
        onGameOver?(score, level)

        overlayLayer.removeAllChildren()
        overlayLayer.addChild(dimPanel())
        let centerX = size.width / 2

        let title = ArcadeFX.label(message, size: 34, color: .white, font: "AvenirNext-Heavy")
        title.position = CGPoint(x: centerX, y: size.height * 0.68)
        title.setScale(0.4)
        title.run(.scale(to: 1, duration: 0.32))
        overlayLayer.addChild(title)

        let scoreText = ArcadeFX.label("SCORE \(score)", size: 24, color: accent, font: "AvenirNext-Heavy")
        scoreText.position = CGPoint(x: centerX, y: size.height * 0.58)
        overlayLayer.addChild(scoreText)

        if isRecord {
            let record = ArcadeFX.label("★ 新紀錄！", size: 18, color: .systemYellow, font: "AvenirNext-Heavy")
            record.position = CGPoint(x: centerX, y: size.height * 0.52)
            record.run(.repeatForever(.sequence([.scale(to: 1.12, duration: 0.45), .scale(to: 1, duration: 0.45)])))
            overlayLayer.addChild(record)
        } else {
            let best = ArcadeFX.label("BEST \(bestScore)", size: 15, color: .white.withAlphaComponent(0.7), font: "AvenirNext-DemiBold")
            best.position = CGPoint(x: centerX, y: size.height * 0.52)
            overlayLayer.addChild(best)
        }

        let restart = ArcadeFX.pillButton("再玩一次", name: "btn_restart", color: accent)
        restart.position = CGPoint(x: centerX, y: size.height * 0.40)
        overlayLayer.addChild(restart)

        let exit = ArcadeFX.pillButton("回遊戲選單", name: "btn_exit", color: SKColor.white.withAlphaComponent(0.18))
        exit.position = CGPoint(x: centerX, y: size.height * 0.31)
        overlayLayer.addChild(exit)
    }

    // MARK: - Phase control

    private func beginPlay() {
        overlayLayer.removeAllChildren()
        phase = .playing
        gameLayer.isPaused = false
        physicsWorld.speed = 1
        lastUpdateTime = 0
        ArcadeFX.Haptic.light()
        gameDidStart()
    }

    func pauseGame() {
        guard phase == .playing else { return }
        phase = .paused
        gameLayer.isPaused = true
        physicsWorld.speed = 0
        showPauseOverlay()
    }

    private func resumeGame() {
        guard phase == .paused else { return }
        overlayLayer.removeAllChildren()
        phase = .playing
        gameLayer.isPaused = false
        physicsWorld.speed = 1
        lastUpdateTime = 0
    }

    // MARK: - Touch routing

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        // 1. 按鈕攔截（任何 phase）
        for node in nodes(at: point) {
            switch node.name {
            case "btn_exit":
                ArcadeFX.Haptic.light()
                onExit?()
                return
            case "btn_pause":
                if phase == .playing { ArcadeFX.Haptic.light(); pauseGame() }
                return
            case "btn_resume":
                ArcadeFX.Haptic.light()
                resumeGame()
                return
            case "btn_restart":
                ArcadeFX.Haptic.light()
                onRestart?()
                return
            case "btn_coach":
                ArcadeFX.Haptic.light()
                onRequestCoach?()
                return
            default:
                continue
            }
        }

        // 2. phase 轉換
        switch phase {
        case .ready:
            beginPlay()
        case .playing:
            gameTouchBegan(at: point)
        case .paused, .gameOver:
            break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard phase == .playing, let touch = touches.first else { return }
        gameTouchMoved(to: touch.location(in: self), previous: touch.previousLocation(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard phase == .playing, let touch = touches.first else { return }
        gameTouchEnded(at: touch.location(in: self))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard phase == .playing, let touch = touches.first else { return }
        gameTouchEnded(at: touch.location(in: self))
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        guard phase == .playing else { return }
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let delta = min(currentTime - lastUpdateTime, 1.0 / 20.0)
        lastUpdateTime = currentTime
        gameUpdate(deltaTime: delta, currentTime: currentTime)
    }

    // MARK: - Helpers

    func addScore(_ amount: Int) {
        score += amount
    }

    func flash(_ text: String, color: SKColor = .systemYellow, fontSize: CGFloat = 30) {
        let label = ArcadeFX.label(text, size: fontSize, color: color, font: "AvenirNext-Heavy")
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 600
        label.setScale(0.5)
        addChild(label)
        label.run(.sequence([
            .scale(to: 1.15, duration: 0.18),
            .wait(forDuration: 0.4),
            .group([.fadeOut(withDuration: 0.4), .moveBy(x: 0, y: 30, duration: 0.4)]),
            .removeFromParent()
        ]))
    }
}
