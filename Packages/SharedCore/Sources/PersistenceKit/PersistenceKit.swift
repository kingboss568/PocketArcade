import Foundation

public struct SourceTrace: Codable, Hashable, Sendable {
    public let sourceName: String
    public let sourceURL: String
    public let fetchedAt: Date
    public let licenseNote: String

    public init(sourceName: String, sourceURL: String, fetchedAt: Date, licenseNote: String) {
        self.sourceName = sourceName
        self.sourceURL = sourceURL
        self.fetchedAt = fetchedAt
        self.licenseNote = licenseNote
    }
}

public protocol SourceTraceable {
    var sourceName: String { get }
    var sourceURL: String { get }
    var fetchedAt: Date { get }
    var licenseNote: String { get }
}

public struct ScoreSnapshot: Codable, Hashable, Sendable {
    public let gameID: String
    public let score: Int
    public let level: Int
    public let playedAt: Date

    public init(gameID: String, score: Int, level: Int, playedAt: Date) {
        self.gameID = gameID
        self.score = score
        self.level = level
        self.playedAt = playedAt
    }
}

public enum ProgressCalculator {
    public static func mergedHighScore(existing: Int, candidate: Int) -> Int {
        max(existing, candidate)
    }

    public static func mergedHighestLevel(existing: Int, candidate: Int) -> Int {
        max(existing, candidate)
    }

    public static func unlockPercentage(unlockedCount: Int, totalCount: Int) -> Double {
        guard totalCount > 0 else { return 0 }
        return min(1, max(0, Double(unlockedCount) / Double(totalCount)))
    }

    public static func isGameUnlocked(isFree: Bool, hasUnlockAll: Bool) -> Bool {
        isFree || hasUnlockAll
    }
}
