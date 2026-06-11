import SpriteKit

/// 極速閃避：三車道滑動切換，閃避來車、收集金幣，速度持續提升。
final class LaneRacerScene: BaseArcadeScene {

    private enum ObjectKind { case car, coin }

    private struct RoadObject {
        let node: SKNode
        let kind: ObjectKind
        let lane: Int
    }

    private var playerCar: SKLabelNode!
    private var currentLane = 1
    private var objects: [RoadObject] = []
    private var roadSpeed: CGFloat = 320
    private var spawnAccumulator: TimeInterval = 0
    private var distance: CGFloat = 0
    private var laneMarkers: [SKShapeNode] = []
    private var swipeStart: CGPoint?
    private var roadLeft: CGFloat = 0
    private var roadWidth: CGFloat = 0
    private var combo = 0

    private func laneX(_ lane: Int) -> CGFloat {
        roadLeft + roadWidth / 6 + roadWidth / 3 * CGFloat(lane)
    }

    override func setupBackground() {
        ArcadeFX.gradientBackground(in: self,
                                    top: UIColor(red: 0.05, green: 0.07, blue: 0.12, alpha: 1),
                                    bottom: UIColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 1))
    }

    override func setupGame() {
        roadWidth = size.width * 0.82
        roadLeft = (size.width - roadWidth) / 2

        // 路面
        let road = SKSpriteNode(color: SKColor(white: 0.13, alpha: 1), size: CGSize(width: roadWidth, height: playTop - playBottom))
        road.position = CGPoint(x: size.width / 2, y: (playTop + playBottom) / 2)
        road.zPosition = 1
        gameLayer.addChild(road)

        // 路肩
        for x in [roadLeft, roadLeft + roadWidth] {
            let edge = SKShapeNode(rect: CGRect(x: x - 3, y: playBottom, width: 6, height: playTop - playBottom))
            edge.fillColor = accent.withAlphaComponent(0.85)
            edge.strokeColor = .clear
            edge.glowWidth = 3
            edge.zPosition = 2
            gameLayer.addChild(edge)
        }

        // 車道虛線（滾動）
        for laneLine in 1...2 {
            let x = roadLeft + roadWidth / 3 * CGFloat(laneLine)
            var y = playBottom
            while y < playTop + 60 {
                let dash = SKShapeNode(rect: CGRect(x: -3, y: -22, width: 6, height: 44), cornerRadius: 3)
                dash.fillColor = SKColor(white: 0.85, alpha: 0.5)
                dash.strokeColor = .clear
                dash.position = CGPoint(x: x, y: y)
                dash.zPosition = 3
                gameLayer.addChild(dash)
                laneMarkers.append(dash)
                y += 90
            }
        }

        playerCar = ArcadeFX.emojiNode("🏎️", size: 52)
        playerCar.position = CGPoint(x: laneX(1), y: playBottom + 110)
        playerCar.zPosition = 50
        gameLayer.addChild(playerCar)
    }

    // MARK: - Touch

    override func gameTouchBegan(at point: CGPoint) { swipeStart = point }

    override func gameTouchEnded(at point: CGPoint) {
        guard let start = swipeStart else { return }
        swipeStart = nil
        let dx = point.x - start.x
        if abs(dx) > 26 {
            changeLane(direction: dx > 0 ? 1 : -1)
        } else {
            // 點擊左右半邊也可換道
            changeLane(direction: point.x > size.width / 2 ? 1 : -1)
        }
    }

    private func changeLane(direction: Int) {
        let newLane = min(max(currentLane + direction, 0), 2)
        guard newLane != currentLane else { return }
        currentLane = newLane
        ArcadeFX.Haptic.light()
        let move = SKAction.moveTo(x: laneX(newLane), duration: 0.14)
        move.timingMode = .easeOut
        playerCar.run(move)
        playerCar.run(.sequence([.rotate(toAngle: direction > 0 ? -0.16 : 0.16, duration: 0.1), .rotate(toAngle: 0, duration: 0.14)]))
    }

    // MARK: - Update

    override func gameUpdate(deltaTime: TimeInterval, currentTime: TimeInterval) {
        let dt = CGFloat(deltaTime)
        distance += roadSpeed * dt
        roadSpeed = min(roadSpeed + 6 * dt, 720)
        let newLevel = 1 + Int(distance / 4000)
        if newLevel != level {
            level = newLevel
            flash("LV \(level) 加速！", color: accent, fontSize: 22)
        }

        // 虛線滾動
        for marker in laneMarkers {
            marker.position.y -= roadSpeed * dt
            if marker.position.y < playBottom - 30 { marker.position.y += (playTop - playBottom) + 90 }
        }

        // 生成物件
        spawnAccumulator += deltaTime
        let interval = TimeInterval(max(0.9 - Double(roadSpeed - 320) / 700, 0.45))
        if spawnAccumulator > interval {
            spawnAccumulator = 0
            spawnObject()
        }

        // 移動物件 + 碰撞
        for index in objects.indices.reversed() {
            let object = objects[index]
            object.node.position.y -= roadSpeed * dt

            if abs(object.node.position.y - playerCar.position.y) < 46 && object.lane == currentLane {
                if object.kind == .coin {
                    combo += 1
                    let points = 10 * min(combo, 5)
                    addScore(points)
                    ArcadeFX.floatingScore("+\(points)", at: object.node.position, in: gameLayer, color: .systemYellow, fontSize: 15)
                    ArcadeFX.burst(in: gameLayer, at: object.node.position, color: .systemYellow, count: 8, speed: 60)
                    ArcadeFX.Haptic.medium()
                    object.node.removeFromParent()
                    objects.remove(at: index)
                    continue
                } else {
                    ArcadeFX.burst(in: gameLayer, at: playerCar.position, color: .systemRed, count: 30, speed: 200)
                    ArcadeFX.Haptic.error()
                    endGame(message: "撞車了！💥")
                    return
                }
            }

            if object.node.position.y < playBottom - 50 {
                if object.kind == .car { addScore(5); combo = 0 }
                object.node.removeFromParent()
                objects.remove(at: index)
            }
        }
    }

    private func spawnObject() {
        // 確保至少一條安全車道：找出最近頂部已被占用的車道
        let recentLanes = Set(objects.filter { $0.node.position.y > playTop - 200 && $0.kind == .car }.map(\.lane))
        var available = [0, 1, 2].filter { recentLanes.contains($0) == false }
        if available.count <= 1 { return }
        available.shuffle()
        let lane = available[0]

        let isCoin = Int.random(in: 0..<4) == 0
        let node: SKLabelNode
        if isCoin {
            node = ArcadeFX.emojiNode("🪙", size: 32)
            node.run(.repeatForever(.sequence([.scale(to: 1.15, duration: 0.4), .scale(to: 0.9, duration: 0.4)])))
        } else {
            let cars = ["🚗", "🚕", "🚙", "🚓", "🚚", "🚌"]
            node = ArcadeFX.emojiNode(cars.randomElement()!, size: 50)
            node.zRotation = .pi   // 對向來車
        }
        node.position = CGPoint(x: laneX(lane), y: playTop + 60)
        node.zPosition = 40
        gameLayer.addChild(node)
        objects.append(RoadObject(node: node, kind: isCoin ? .coin : .car, lane: lane))
    }
}
