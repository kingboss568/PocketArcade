import Foundation
import SharedCore

public enum ArcadeGameID: String, CaseIterable, Codable, Identifiable, Sendable {
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
