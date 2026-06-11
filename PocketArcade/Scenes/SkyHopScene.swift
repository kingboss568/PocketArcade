import SpriteKit

/// 跳跳樂：自動彈跳往上爬，拖曳控制左右，四種跳台，高度即分數。
final class SkyHopScene: BaseArcadeScene {

    private enum PlatformKind { case normal, moving, fragile, spring }

    private struct Platform {
        let node: SKNode
        let kind: PlatformKind
        var direction: CGFloat = 1
        var broken = false
    }

    private var player: SKLabelNode!
    private var velocityY: CGFloat = 0
    private var targetX: CGFloat = 0
    private var platforms: [Platform] = []
    private var cameraNode = SKCameraNode()
    private var maxHeight: CGFloat = 0
    private var highestPlatformY: CGFloat = 0
    private let platformSize = CGSize(width: 74, height: 14)
    private let gravity: CGFloat = -1150
    private let jumpVelocity: CGFloat = 620
    private let springVelocity: CGFloat = 1000

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.10, green: 0.16, blue: 0.32, alpha: 1),
                                    bottom: UIColor(red: 0.04, green: 0.07, blue: 0.16, alpha: 1))
        ArcadeFX.addStarfield(to: self, count: 50)
    }

    override func setupGame() {
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cameraNode)
        camera = cameraNode

        targetX = size.width / 2
        player = ArcadeFX.emojiNode("🐰", size: 40)
        player.position = CGPoint(x: size.width / 2, y: playBottom + 120)
        player.zPosition = 50
        gameLayer.addChild(player)

        // 起始平台
        let basePlatform = makePlatform(kind: .normal, at: CGPoint(x: size.width / 2, y: playBottom + 80))
        platforms.append(basePlatform)
        highestPlatformY = playBottom + 80

        for _ in 0..<14 { spawnPlatform() }
        velocityY = jumpVelocity
    }

    private func makePlatform(kind: PlatformKind, at position: CGPoint) -> Platform {
        let node = SKNode()
        let color: SKColor
        switch kind {
        case .normal: color = SKColor(red: 0.36, green: 0.84, blue: 0.52, alpha: 1)
        case .moving: color = SKColor(red: 0.40, green: 0.66, blue: 1, alpha: 1)
        case .fragile: color = SKColor(red: 0.78, green: 0.58, blue: 0.40, alpha: 1)
        case .spring: color = SKColor(red: 1, green: 0.78, blue: 0.28, alpha: 1)
        }
        let shape = ArcadeFX.roundedRect(size: platformSize, radius: 7, fill: color, stroke: .white.withAlphaComponent(0.5), lineWidth: 1)
        shape.glowWidth = 2
        node.addChild(shape)
        if kind == .spring {
            let spring = ArcadeFX.emojiNode("🌀", size: 18)
            spring.position = CGPoint(x: 0, y: 14)
            node.addChild(spring)
        }
        if kind == .fragile {
            let crack = ArcadeFX.label("⌁", size: 12, color: .black.withAlphaComponent(0.4))
            node.addChild(crack)
        }
        node.position = position
        node.zPosition = 10
        gameLayer.addChild(node)
        return Platform(node: node, kind: kind)
    }

    private func spawnPlatform() {
        let gap = CGFloat.random(in: 56...96) + min(maxHeight / 90, 30)
        highestPlatformY += gap
        let x = CGFloat.random(in: platformSize.width / 2 + 10...(size.width - platformSize.width / 2 - 10))
        let roll = Int.random(in: 0..<10)
        let difficulty = min(Int(maxHeight / 1500), 3)
        let kind: PlatformKind
        switch roll {
        case 0...(5 - difficulty): kind = .normal
        case 6, 7: kind = .moving
        case 8: kind = .fragile
        default: kind = .spring
        }
        platforms.append(makePlatform(kind: kind, at: CGPoint(x: x, y: highestPlatformY)))
    }

    override func gameTouchBegan(at point: CGPoint) { targetX = point.x }
    override func gameTouchMoved(to point: CGPoint, previous: CGPoint) { targetX = point.x }

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        let dt = CGFloat(deltaTime)

        // 水平移動（平滑跟隨 + 邊緣環繞）
        player.position.x += (targetX - player.position.x) * min(1, dt * 10)
        if player.position.x < -20 { player.position.x = size.width + 20 }
        if player.position.x > size.width + 20 { player.position.x = -20 }

        // 垂直物理
        velocityY += gravity * dt
        player.position.y += velocityY * dt
        player.xScale = velocityY > 0 ? 1 : 1
        player.yScale = velocityY > 200 ? 1.08 : 1

        // 平台碰撞（只在下落時）
        if velocityY < 0 {
            for index in platforms.indices {
                let platform = platforms[index]
                guard platform.broken == false else { continue }
                let p = platform.node.position
                if abs(player.position.x - p.x) < platformSize.width / 2 + 14,
                   player.position.y - 18 > p.y, player.position.y - 18 + velocityY * dt <= p.y + 10 {
                    land(on: index)
                    break
                }
            }
        }

        // 移動平台
        for index in platforms.indices where platforms[index].kind == .moving {
            var platform = platforms[index]
            platform.node.position.x += 80 * platform.direction * dt
            let halfWidth = platformSize.width / 2
            if platform.node.position.x > size.width - halfWidth - 6 { platform.direction = -1 }
            if platform.node.position.x < halfWidth + 6 { platform.direction = 1 }
            platforms[index] = platform
        }

        // 分數 = 高度
        if player.position.y > maxHeight {
            maxHeight = player.position.y
            score = Int(maxHeight / 10)
            level = 1 + Int(maxHeight / 2000)
        }

        // 鏡頭跟隨
        let cameraTargetY = max(player.position.y + size.height * 0.18, size.height / 2)
        if cameraTargetY > cameraNode.position.y {
            cameraNode.position.y += (cameraTargetY - cameraNode.position.y) * min(1, dt * 6)
        }

        // 補平台、清理舊平台
        while highestPlatformY < cameraNode.position.y + size.height { spawnPlatform() }
        platforms.removeAll { platform in
            if platform.node.position.y < cameraNode.position.y - size.height * 0.65 {
                platform.node.removeFromParent()
                return true
            }
            return false
        }

        // 掉出畫面
        if player.position.y < cameraNode.position.y - size.height * 0.58 {
            endGame(message: "掉下去了！")
        }
    }

    private func land(on index: Int) {
        let platform = platforms[index]
        switch platform.kind {
        case .spring:
            velocityY = springVelocity
            flash("彈簧跳！", color: .systemYellow, fontSize: 20)
            ArcadeFX.burst(in: gameLayer, at: platform.node.position, color: .systemYellow, count: 14)
            ArcadeFX.Haptic.success()
        case .fragile:
            velocityY = jumpVelocity
            platforms[index].broken = true
            platform.node.run(.sequence([
                .group([.fadeOut(withDuration: 0.3), .moveBy(x: 0, y: -40, duration: 0.3)]),
                .removeFromParent()
            ]))
            ArcadeFX.Haptic.medium()
        default:
            velocityY = jumpVelocity
            ArcadeFX.Haptic.light()
        }
        platform.node.run(.sequence([.scaleY(to: 0.7, duration: 0.06), .scaleY(to: 1, duration: 0.1)]))
    }
}
