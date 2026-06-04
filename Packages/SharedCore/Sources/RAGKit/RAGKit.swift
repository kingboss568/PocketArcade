import Foundation

public struct RAGChunk: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let body: String
    public let tokens: [String]
    public let sourceName: String
    public let sourceURL: String
    public let fetchedAt: Date
    public let licenseNote: String

    public init(id: String, title: String, body: String, tokens: [String], sourceName: String, sourceURL: String, fetchedAt: Date, licenseNote: String) {
        self.id = id
        self.title = title
        self.body = body
        self.tokens = tokens
        self.sourceName = sourceName
        self.sourceURL = sourceURL
        self.fetchedAt = fetchedAt
        self.licenseNote = licenseNote
    }
}

public struct RAGVectorIndex: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let chunks: [RAGChunk]

    public init(generatedAt: Date, chunks: [RAGChunk]) {
        self.generatedAt = generatedAt
        self.chunks = chunks
    }
}

public struct RAGSearchResult: Equatable, Sendable {
    public let chunk: RAGChunk
    public let score: Int
    public let snippet: String

    public init(chunk: RAGChunk, score: Int, snippet: String) {
        self.chunk = chunk
        self.score = score
        self.snippet = snippet
    }
}

public protocol RAGSearching: Sendable {
    func search(_ query: String, limit: Int) -> [RAGSearchResult]
}

public struct LocalRAGSearchService: RAGSearching {
    private let chunks: [RAGChunk]

    public init(chunks: [RAGChunk]) {
        self.chunks = chunks
    }

    public func search(_ query: String, limit: Int = 3) -> [RAGSearchResult] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized.isEmpty == false else { return [] }
        let queryTokens = Self.tokenize(normalized)

        return chunks.compactMap { chunk in
            let tokenScore = queryTokens.reduce(0) { score, token in
                score + (chunk.tokens.contains(token) ? 3 : 0)
            }
            let titleScore = chunk.title.lowercased().contains(normalized) ? 5 : 0
            let bodyScore = chunk.body.lowercased().contains(normalized) ? 4 : 0
            let total = tokenScore + titleScore + bodyScore
            guard total > 0 else { return nil }
            return RAGSearchResult(chunk: chunk, score: total, snippet: Self.snippet(from: chunk.body, query: normalized))
        }
        .sorted { lhs, rhs in lhs.score == rhs.score ? lhs.chunk.id < rhs.chunk.id : lhs.score > rhs.score }
        .prefix(max(limit, 0))
        .map { $0 }
    }

    public static func tokenize(_ text: String) -> [String] {
        let separators = CharacterSet.alphanumerics.inverted
        let latin = text.lowercased().components(separatedBy: separators).filter { $0.isEmpty == false }
        let compactChineseHints = ["磚塊", "貪吃蛇", "方塊", "青蛙", "泡泡", "地鼠", "彈珠", "五子棋", "離線", "解鎖"]
        return Array(Set(latin + compactChineseHints.filter { text.contains($0) }))
    }

    private static func snippet(from body: String, query: String) -> String {
        if let range = body.lowercased().range(of: query) {
            let before = min(24, body.distance(from: body.startIndex, to: range.lowerBound))
            let after = min(72, body.distance(from: range.upperBound, to: body.endIndex))
            let start = body.index(range.lowerBound, offsetBy: -before)
            let end = body.index(range.upperBound, offsetBy: after)
            return String(body[start..<end])
        }
        return String(body.prefix(96))
    }
}
