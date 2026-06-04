import Foundation

public struct ArcadeScoreExportRow: Equatable, Sendable {
    public let gameTitle: String
    public let highScore: Int
    public let highestLevel: Int
    public let playCount: Int
    public let lastPlayedAt: Date?

    public init(gameTitle: String, highScore: Int, highestLevel: Int, playCount: Int, lastPlayedAt: Date?) {
        self.gameTitle = gameTitle
        self.highScore = highScore
        self.highestLevel = highestLevel
        self.playCount = playCount
        self.lastPlayedAt = lastPlayedAt
    }
}

public struct CSVExportService {
    public init() {}

    public func makeCSV(rows: [ArcadeScoreExportRow]) -> String {
        let formatter = ISO8601DateFormatter()
        let header = ["Game", "High Score", "Highest Level", "Play Count", "Last Played"].joined(separator: ",")
        let lines = rows.map { row in
            [
                escape(row.gameTitle),
                String(row.highScore),
                String(row.highestLevel),
                String(row.playCount),
                row.lastPlayedAt.map { formatter.string(from: $0) } ?? ""
            ].joined(separator: ",")
        }
        return ([header] + lines).joined(separator: "\n")
    }

    private func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}

public struct PDFExportManifest: Equatable, Sendable {
    public let title: String
    public let generatedAt: Date
    public let rows: [ArcadeScoreExportRow]
    public let disclaimer: String

    public init(title: String, generatedAt: Date, rows: [ArcadeScoreExportRow], disclaimer: String) {
        self.title = title
        self.generatedAt = generatedAt
        self.rows = rows
        self.disclaimer = disclaimer
    }

    public var suggestedFileName: String {
        "PocketArcade-Scorecard.pdf"
    }
}
