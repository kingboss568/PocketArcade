import SpriteKit
import UIKit

/// 共用視覺特效工廠：漸層、光暈、粒子、UI 元件、震動回饋。
enum ArcadeFX {

    // MARK: - Accent colors

    static func accent(for id: ArcadeGameID) -> SKColor {
        switch id {
        case .brickBlitz: return SKColor(red: 1.00, green: 0.32, blue: 0.42, alpha: 1)
        case .snakeEVO: return SKColor(red: 0.30, green: 0.92, blue: 0.48, alpha: 1)
        case .stackAttack: return SKColor(red: 1.00, green: 0.62, blue: 0.22, alpha: 1)
        case .frogDash: return SKColor(red: 0.42, green: 0.94, blue: 0.78, alpha: 1)
        case .bubblePop: return SKColor(red: 1.00, green: 0.48, blue: 0.74, alpha: 1)
        case .moleMania: return SKColor(red: 0.86, green: 0.64, blue: 0.38, alpha: 1)
        case .pinballPro: return SKColor(red: 0.72, green: 0.46, blue: 1.00, alpha: 1)
        case .twentyFortyEight: return SKColor(red: 1.00, green: 0.84, blue: 0.30, alpha: 1)
        case .asteroidAce: return SKColor(red: 0.36, green: 0.84, blue: 1.00, alpha: 1)
        case .gomokuGo: return SKColor(red: 0.92, green: 0.90, blue: 0.84, alpha: 1)
        case .pongDuel: return SKColor(red: 0.46, green: 0.98, blue: 0.92, alpha: 1)
        case .skyHop: return SKColor(red: 0.56, green: 0.86, blue: 1.00, alpha: 1)
        case .rocketRush: return SKColor(red: 1.00, green: 0.56, blue: 0.30, alpha: 1)
        case .laneRacer: return SKColor(red: 1.00, green: 0.30, blue: 0.30, alpha: 1)
        case .memoryMatch: return SKColor(red: 0.66, green: 0.74, blue: 1.00, alpha: 1)
        case .reversiRoyale: return SKColor(red: 0.36, green: 0.88, blue: 0.62, alpha: 1)
        case .mineSweeper: return SKColor(red: 0.80, green: 0.80, blue: 0.88, alpha: 1)
        case .gemCrush: return SKColor(red: 0.98, green: 0.42, blue: 0.86, alpha: 1)
        case .invaderStorm: return SKColor(red: 0.52, green: 1.00, blue: 0.46, alpha: 1)
        case .fruitCatch: return SKColor(red: 1.00, green: 0.76, blue: 0.28, alpha: 1)
        }
    }

    // MARK: - Textures

    private static var textureCache: [String: SKTexture] = [:]

    static func gradientTexture(size: CGSize, top: UIColor, bottom: UIColor) -> SKTexture {
        let key = "grad_\(Int(size.width))x\(Int(size.height))_\(top.description)_\(bottom.description)"
        if let cached = textureCache[key] { return cached }
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
            ctx.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
        }
        let texture = SKTexture(image: image)
        textureCache[key] = texture
        return texture
    }

    static func glowTexture(radius: CGFloat, color: UIColor) -> SKTexture {
        let key = "glow_\(Int(radius))_\(color.description)"
        if let cached = textureCache[key] { return cached }
        let size = CGSize(width: radius * 2, height: radius * 2)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let colors = [color.withAlphaComponent(0.85).cgColor, color.withAlphaComponent(0).cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
            ctx.cgContext.drawRadialGradient(gradient, startCenter: CGPoint(x: radius, y: radius), startRadius: 0, endCenter: CGPoint(x: radius, y: radius), endRadius: radius, options: [])
        }
        let texture = SKTexture(image: image)
        textureCache[key] = texture
        return texture
    }

    static var sparkTexture: SKTexture = {
        glowTexture(radius: 8, color: .white)
    }()

    // MARK: - Nodes

    static func gradientBackground(in scene: SKScene, top: UIColor, bottom: UIColor) {
        let node = SKSpriteNode(texture: gradientTexture(size: CGSize(width: 64, height: 512), top: top, bottom: bottom))
        node.size = CGSize(width: scene.size.width, height: scene.size.height)
        node.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        node.zPosition = -100
        node.name = "fx_background"
        scene.addChild(node)
    }

    static func addStarfield(to scene: SKScene, count: Int = 46, color: UIColor = .white) {
        for _ in 0..<count {
            let radius = CGFloat.random(in: 0.7...2.1)
            let star = SKSpriteNode(texture: sparkTexture)
            star.size = CGSize(width: radius * 3, height: radius * 3)
            star.color = color
            star.colorBlendFactor = 1
            star.alpha = CGFloat.random(in: 0.18...0.6)
            star.position = CGPoint(x: .random(in: 0...scene.size.width), y: .random(in: 0...scene.size.height))
            star.zPosition = -90
            star.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.12, duration: Double.random(in: 0.8...2.2)),
                .fadeAlpha(to: 0.6, duration: Double.random(in: 0.8...2.2))
            ])))
            scene.addChild(star)
        }
    }

    static func label(_ text: String, size: CGFloat, color: SKColor = .white, font: String = "AvenirNext-Bold") -> SKLabelNode {
        let node = SKLabelNode(fontNamed: font)
        node.text = text
        node.fontSize = size
        node.fontColor = color
        node.verticalAlignmentMode = .center
        return node
    }

    static func emojiNode(_ emoji: String, size: CGFloat) -> SKLabelNode {
        let node = SKLabelNode(text: emoji)
        node.fontSize = size
        node.verticalAlignmentMode = .center
        node.horizontalAlignmentMode = .center
        return node
    }

    static func roundedRect(size: CGSize, radius: CGFloat, fill: SKColor, stroke: SKColor = .clear, lineWidth: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: radius)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = lineWidth
        return node
    }

    static func glowDot(radius: CGFloat, color: SKColor) -> SKNode {
        let container = SKNode()
        let glow = SKSpriteNode(texture: glowTexture(radius: radius * 2.4, color: color))
        glow.alpha = 0.6
        container.addChild(glow)
        let core = SKShapeNode(circleOfRadius: radius)
        core.fillColor = color
        core.strokeColor = .white.withAlphaComponent(0.85)
        core.lineWidth = 1.4
        container.addChild(core)
        return container
    }

    /// 膠囊按鈕，name 由場景 touchesBegan 比對。
    static func pillButton(_ text: String, name: String, width: CGFloat = 220, height: CGFloat = 52, color: SKColor, textColor: SKColor = .white) -> SKNode {
        let container = SKNode()
        container.name = name
        let bg = roundedRect(size: CGSize(width: width, height: height), radius: height / 2, fill: color.withAlphaComponent(0.92), stroke: .white.withAlphaComponent(0.7), lineWidth: 1.5)
        bg.name = name
        container.addChild(bg)
        let label = label(text, size: 19, color: textColor, font: "AvenirNext-Heavy")
        label.name = name
        container.addChild(label)
        return container
    }

    /// 圓形小圖示按鈕（暫停、關閉）。
    static func circleButton(symbol: String, name: String, radius: CGFloat = 19) -> SKNode {
        let container = SKNode()
        container.name = name
        let bg = SKShapeNode(circleOfRadius: radius)
        bg.fillColor = SKColor.black.withAlphaComponent(0.45)
        bg.strokeColor = .white.withAlphaComponent(0.35)
        bg.lineWidth = 1.2
        bg.name = name
        container.addChild(bg)
        let label = label(symbol, size: radius * 0.95, color: .white, font: "AvenirNext-Bold")
        label.name = name
        container.addChild(label)
        return container
    }

    // MARK: - Particles

    static func burst(in parent: SKNode, at point: CGPoint, color: UIColor, count: Int = 16, speed: CGFloat = 130, zPosition: CGFloat = 40) {
        for _ in 0..<count {
            let spark = SKSpriteNode(texture: sparkTexture)
            spark.size = CGSize(width: CGFloat.random(in: 5...11), height: CGFloat.random(in: 5...11))
            spark.color = color
            spark.colorBlendFactor = 1
            spark.position = point
            spark.zPosition = zPosition
            parent.addChild(spark)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: speed * 0.35...speed)
            let move = SKAction.move(by: CGVector(dx: cos(angle) * distance, dy: sin(angle) * distance), duration: 0.5)
            move.timingMode = .easeOut
            spark.run(.sequence([.group([move, .fadeOut(withDuration: 0.5), .scale(to: 0.2, duration: 0.5)]), .removeFromParent()]))
        }
    }

    static func trailEmitter(color: UIColor, birthRate: CGFloat = 60, lifetime: CGFloat = 0.45, scale: CGFloat = 0.16) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = sparkTexture
        emitter.particleBirthRate = birthRate
        emitter.particleLifetime = lifetime
        emitter.particleAlpha = 0.7
        emitter.particleAlphaSpeed = -1.4
        emitter.particleScale = scale
        emitter.particleScaleSpeed = -0.25
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1
        emitter.particleSpeed = 12
        emitter.emissionAngleRange = .pi * 2
        emitter.targetNode = nil
        return emitter
    }

    static func floatingScore(_ text: String, at point: CGPoint, in parent: SKNode, color: SKColor = .yellow, fontSize: CGFloat = 20) {
        let node = label(text, size: fontSize, color: color, font: "AvenirNext-Heavy")
        node.position = point
        node.zPosition = 60
        parent.addChild(node)
        let rise = SKAction.moveBy(x: 0, y: 46, duration: 0.7)
        rise.timingMode = .easeOut
        node.run(.sequence([.group([rise, .sequence([.wait(forDuration: 0.3), .fadeOut(withDuration: 0.4)])]), .removeFromParent()]))
    }

    // MARK: - Haptics

    enum Haptic {
        private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
        private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
        private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        private static let notifyGenerator = UINotificationFeedbackGenerator()

        static func light() { lightGenerator.impactOccurred() }
        static func medium() { mediumGenerator.impactOccurred() }
        static func heavy() { heavyGenerator.impactOccurred() }
        static func success() { notifyGenerator.notificationOccurred(.success) }
        static func warning() { notifyGenerator.notificationOccurred(.warning) }
        static func error() { notifyGenerator.notificationOccurred(.error) }
    }
}
