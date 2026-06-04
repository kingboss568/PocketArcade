import Foundation
import SwiftData
import SharedCore

@MainActor
enum GameProgressStore {
    static func record(score: Int, level: Int, for game: GameModel, in context: ModelContext) throws -> GameProgress {
        let id = game.id.rawValue
        let descriptor = FetchDescriptor<GameProgress>(predicate: #Predicate { $0.gameID == id })
        let existing = try context.fetch(descriptor).first
        let record = existing ?? GameProgress(gameID: id)
        if existing == nil { context.insert(record) }
        record.highScore = ProgressCalculator.mergedHighScore(existing: record.highScore, candidate: score)
        record.highestLevel = ProgressCalculator.mergedHighestLevel(existing: record.highestLevel, candidate: level)
        record.playCount += 1
        record.lastPlayedAt = .now
        UserDefaults.standard.set(record.highScore, forKey: game.id.userDefaultsHighScoreKey)
        if game.id == .frogDash { UserDefaults.standard.set(record.highestLevel, forKey: "lastlevel_frogdash") }
        if game.id == .bubblePop { UserDefaults.standard.set(record.highestLevel, forKey: "lastlevel_bubblepop") }
        try context.save()
        return record
    }

    static func row(for game: GameModel, progress: GameProgress?) -> ArcadeScoreExportRow {
        ArcadeScoreExportRow(
            gameTitle: game.displayTitle,
            highScore: progress?.highScore ?? UserDefaults.standard.integer(forKey: game.id.userDefaultsHighScoreKey),
            highestLevel: progress?.highestLevel ?? 1,
            playCount: progress?.playCount ?? 0,
            lastPlayedAt: progress?.lastPlayedAt
        )
    }
}
