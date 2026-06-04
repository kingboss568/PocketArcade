import Foundation
import SharedCore

public enum RAGIndexLoader {
    public static func load(bundle: Bundle = .main) -> RAGVectorIndex {
        guard let url = bundle.url(forResource: "RAGVectorIndex", withExtension: "json") else {
            return RAGVectorIndex(generatedAt: .now, chunks: [])
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(RAGVectorIndex.self, from: Data(contentsOf: url))
        } catch {
            return RAGVectorIndex(generatedAt: .now, chunks: [])
        }
    }
}
