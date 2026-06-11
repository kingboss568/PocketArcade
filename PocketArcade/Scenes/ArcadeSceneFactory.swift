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
        case .pongDuel: scene = PongDuelScene(game: game)
        case .skyHop: scene = SkyHopScene(game: game)
        case .rocketRush: scene = RocketRushScene(game: game)
        case .laneRacer: scene = LaneRacerScene(game: game)
        case .memoryMatch: scene = MemoryMatchScene(game: game)
        case .reversiRoyale: scene = ReversiRoyaleScene(game: game)
        case .mineSweeper: scene = MineSweeperScene(game: game)
        case .gemCrush: scene = GemCrushScene(game: game)
        case .invaderStorm: scene = InvaderStormScene(game: game)
        case .fruitCatch: scene = FruitCatchScene(game: game)
        }
        scene.scaleMode = .resizeFill
        return scene
    }
}
