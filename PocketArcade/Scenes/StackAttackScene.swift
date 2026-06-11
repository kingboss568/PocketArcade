import SpriteKit

/// 方塊疊疊樂：點擊放下移動中的平板，沒對準的部分被切除，完美堆疊加分加寬。
final class StackAttackScene: BaseArcadeScene {

    private let slabHeight: CGFloat = 26
    private var stack: [(node: SKShapeNode, width: CGFloat, centerX: CGFloat)] = []
    private var movingSlab: SKShapeNode?
    private var movingWidth: CGFloat = 0
    private var moveSpeed: CGFloat = 200
    private var movingRight = true
    private var perfectStreak = 0
    private var cameraNode = SKCameraNode()
    private var hue: CGFloat = 0.55

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.13, green: 0.08, blue: 0.22, alpha: 1),
                                    bottom: UIColor(red: 0.04, green: 0.03, blue: 0.10, alpha: 1))
        ArcadeFX.addStarfield(to: self, count: 40)
    }

    override func setupGame() {
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cameraNode)
        camera = cameraNode

        // 基座
        let baseWidth: CGFloat = 200
        let base = makeSlab(width: baseWidth)
        base.position = CGPoint(x: size.width / 2, y: playBottom + 60)
        gameLayer.addChild(base)
        stack.append((base, baseWidth, size.width / 2))
    }

    override func gameDidStart() {
        spawnMovingSlab()
    }

    private func slabColor() -> SKColor {
        hue += 0.035
        if hue > 1 { hue -= 1 }
        return SKColor(hue: hue, saturation: 0.65, brightness: 0.95, alpha: 1)
    }

    private func makeSlab(width: CGFloat) -> SKShapeNode {
        let node = SKShapeNode(rectOf: CGSize(width: width, height: slabHeight), cornerRadius: 5)
        node.fillColor = slabColor()
        node.strokeColor = .white.withAlphaComponent(0.5)
        node.lineWidth = 1
        node.glowWidth = 2
        return node
    }

    private var topY: CGFloat {
        (stack.last?.node.position.y ?? playBottom + 60)
    }

    private func spawnMovingSlab() {
        guard let top = stack.last else { return }
        movingWidth = top.width
        let slab = makeSlab(width: movingWidth)
        movingRight = Bool.random()
        let y = topY + slabHeight
        slab.position = CGPoint(x: movingRight ? movingWidth / 2 + 4 : size.width - movingWidth / 2 - 4, y: y)
        gameLayer.addChild(slab)
        movingSlab = slab
    }

    // MARK: - Update

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        guard let slab = movingSlab else { return }
        let dt = CGFloat(deltaTime)
        var x = slab.position.x + (movingRight ? moveSpeed : -moveSpeed) * dt
        let halfWidth = movingWidth / 2
        if x > size.width - halfWidth - 4 { x = size.width - halfWidth - 4; movingRight = false }
        if x < halfWidth + 4 { x = halfWidth + 4; movingRight = true }
        slab.position.x = x
    }

    // MARK: - Touch

    override func gameTouchBegan(at point: CGPoint) {
        dropSlab()
    }

    private func dropSlab() {
        guard let slab = movingSlab, let top = stack.last else { return }
        movingSlab = nil

        let overlapLeft = max(slab.position.x - movingWidth / 2, top.centerX - top.width / 2)
        let overlapRight = min(slab.position.x + movingWidth / 2, top.centerX + top.width / 2)
        let overlap = overlapRight - overlapLeft

        // 完全沒疊到
        if overlap <= 4 {
            slab.run(.sequence([
                .group([.moveBy(x: 0, y: -300, duration: 0.55), .rotate(byAngle: movingRight ? -1.2 : 1.2, duration: 0.55), .fadeOut(withDuration: 0.55)]),
                .removeFromParent()
            ]))
            ArcadeFX.Haptic.error()
            endGame(message: "塔倒了！")
            return
        }

        let offset = abs(slab.position.x - top.centerX)
        let isPerfect = offset < 7

        if isPerfect {
            // 完美堆疊：對齊、加分、特效
            perfectStreak += 1
            let bonus = 25 * perfectStreak
            slab.position.x = top.centerX
            stack.append((slab, top.width, top.centerX))
            addScore(10 + bonus)
            ArcadeFX.burst(in: gameLayer, at: CGPoint(x: top.centerX, y: slab.position.y), color: .systemYellow, count: 18)
            ArcadeFX.floatingScore("PERFECT +\(10 + bonus)", at: CGPoint(x: top.centerX, y: slab.position.y + 24), in: gameLayer, color: .systemYellow, fontSize: 17)
            ArcadeFX.Haptic.success()
        } else {
            // 切除超出的部分
            perfectStreak = 0
            let newCenter = (overlapLeft + overlapRight) / 2
            let cutWidth = movingWidth - overlap

            let cutCenterX = slab.position.x > top.centerX ? overlapRight + cutWidth / 2 : overlapLeft - cutWidth / 2
            let falling = SKShapeNode(rectOf: CGSize(width: cutWidth, height: slabHeight), cornerRadius: 4)
            falling.fillColor = slab.fillColor.withAlphaComponent(0.85)
            falling.strokeColor = .clear
            falling.position = CGPoint(x: cutCenterX, y: slab.position.y)
            gameLayer.addChild(falling)
            falling.run(.sequence([
                .group([.moveBy(x: cutCenterX > newCenter ? 40 : -40, y: -280, duration: 0.5), .rotate(byAngle: 0.8, duration: 0.5), .fadeOut(withDuration: 0.5)]),
                .removeFromParent()
            ]))

            let trimmed = makeSlab(width: overlap)
            trimmed.fillColor = slab.fillColor
            trimmed.position = CGPoint(x: newCenter, y: slab.position.y)
            gameLayer.addChild(trimmed)
            slab.removeFromParent()
            stack.append((trimmed, overlap, newCenter))
            addScore(10)
            ArcadeFX.Haptic.medium()
        }

        if stack.count % 10 == 0 {
            level += 1
            flash("第 \(stack.count) 層！", color: accent, fontSize: 24)
        }
        moveSpeed = min(moveSpeed + 7, 460)

        // 鏡頭上移
        let targetY = topY - size.height * 0.32
        if targetY > cameraNode.position.y - size.height / 2 {
            let move = SKAction.moveTo(y: topY + size.height * 0.18, duration: 0.3)
            move.timingMode = .easeOut
            cameraNode.run(move)
        }

        spawnMovingSlab()
    }
}
