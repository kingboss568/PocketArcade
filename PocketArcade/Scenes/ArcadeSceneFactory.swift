import SpriteKit

enum ArcadeSceneFactory {
    static func makeScene(for game: GameModel) -> BaseArcadeScene {
        let scene: BaseArcadeScene
        switch game.id {
        case .brickBlitz: scene = BrickBlitzScene(game: game)
        case .snakeEVO: scene = SnakeEVOScene(game: game)
        case .stackAttack: scene = StackAttackScene(game: game)
        case .frogDash: scene = FrogDashScene(game: game)
        case .bubblePop: scene = BubblePopScene(game: game)
        case .moleMania: scene = MoleManiaScene(game: game)
        case .pinballPro: scene = PinballProScene(game: game)
        case .twentyFortyEight: scene = TwentyFortyEightScene(game: game)
        case .asteroidAce: scene = AsteroidAceScene(game: game)
        case .gomokuGo: scene = GomokuGoScene(game: game)
        }
        scene.scaleMode = .resizeFill
        return scene
    }
}
