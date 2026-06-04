import Foundation
import SwiftData

@Model
final class GameProgress {
    @Attribute(.unique) var gameID: String
    var highScore: Int
    var highestLevel: Int
    var playCount: Int
    var lastPlayedAt: Date?

    init(gameID: String, highScore: Int = 0, highestLevel: Int = 1, playCount: Int = 0, lastPlayedAt: Date? = nil) {
        self.gameID = gameID
        self.highScore = highScore
        self.highestLevel = highestLevel
        self.playCount = playCount
        self.lastPlayedAt = lastPlayedAt
    }
}

@Model
final class PlayerPreference {
    @Attribute(.unique) var key: String
    var boolValue: Bool
    var updatedAt: Date

    init(key: String, boolValue: Bool, updatedAt: Date = .now) {
        self.key = key
        self.boolValue = boolValue
        self.updatedAt = updatedAt
    }
}
