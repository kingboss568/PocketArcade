import Foundation
import SharedCore

public enum ArcadeGameID: String, CaseIterable, Codable, Identifiable, Sendable {
    // 原始 10 款
    case brickBlitz
    case snakeEVO
    case stackAttack
    case frogDash
    case bubblePop
    case moleMania
    case pinballPro
    case twentyFortyEight
    case asteroidAce
    case gomokuGo
    // 擴充 10 款
    case pongDuel
    case skyHop
    case rocketRush
    case laneRacer
    case memoryMatch
    case reversiRoyale
    case mineSweeper
    case gemCrush
    case invaderStorm
    case fruitCatch

    public var id: String { rawValue }

    public var userDefaultsHighScoreKey: String {
        switch self {
        case .brickBlitz: return "highscore_brickblitz"
        case .snakeEVO: return "highscore_snakeevo"
        case .stackAttack: return "highscore_stackattack"
        case .frogDash: return "highscore_frogdash"
        case .bubblePop: return "highscore_bubblepop"
        case .moleMania: return "highscore_molemania"
        case .pinballPro: return "highscore_pinball"
        case .twentyFortyEight: return "highscore_2048plus"
        case .asteroidAce: return "highscore_asteroid"
        case .gomokuGo: return "highscore_gomoku"
        case .pongDuel: return "highscore_pongduel"
        case .skyHop: return "highscore_skyhop"
        case .rocketRush: return "highscore_rocketrush"
        case .laneRacer: return "highscore_laneracer"
        case .memoryMatch: return "highscore_memorymatch"
        case .reversiRoyale: return "highscore_reversi"
        case .mineSweeper: return "highscore_minesweeper"
        case .gemCrush: return "highscore_gemcrush"
        case .invaderStorm: return "highscore_invaderstorm"
        case .fruitCatch: return "highscore_fruitcatch"
        }
    }

    /// 選單分類
    public var category: ArcadeCategory {
        switch self {
        case .brickBlitz, .frogDash, .pinballPro, .asteroidAce, .skyHop, .rocketRush, .laneRacer, .invaderStorm:
            return .action
        case .snakeEVO, .moleMania, .pongDuel, .fruitCatch:
            return .casual
        case .stackAttack, .bubblePop, .twentyFortyEight, .memoryMatch, .mineSweeper, .gemCrush:
            return .puzzle
        case .gomokuGo, .reversiRoyale:
            return .board
        }
    }
}

public enum ArcadeCategory: String, CaseIterable, Sendable {
    case action
    case casual
    case puzzle
    case board

    public var displayName: String {
        switch self {
        case .action: return "動作反應"
        case .casual: return "休閒同樂"
        case .puzzle: return "益智解謎"
        case .board: return "棋盤對弈"
        }
    }
}

public struct GameModel: Identifiable, Codable, Hashable, Sendable, SourceTraceable {
    public let id: ArcadeGameID
    public let title: String
    public let englishTitle: String
    public let reference: String
    public let isFree: Bool
    public let levelCount: Int
    public let leaderboardID: String
    public let mechanics: [String]
    public let sourceName: String
    public let sourceURL: String
    public let fetchedAt: Date
    public let licenseNote: String

    public var lockLabel: String { isFree ? "FREE" : "LOCKED" }
    public var displayTitle: String { "\(title) \(englishTitle)" }
}
