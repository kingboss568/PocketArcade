import XCTest
import SharedCore

final class SharedCoreServiceTests: XCTestCase {
    func testEntitlementResolverMapsBothProductIDs() {
        let snapshot = EntitlementResolver.resolve(verifiedProductIDs: [
            ArcadeProductID.unlockAll.rawValue,
            ArcadeProductID.removeAds.rawValue
        ])
        XCTAssertTrue(snapshot.hasUnlockAll)
        XCTAssertTrue(snapshot.hasRemoveAds)
    }

    func testCSVExportEscapesCommasAndQuotes() {
        let csv = CSVExportService().makeCSV(rows: [
            ArcadeScoreExportRow(gameTitle: "Bubble, \"Pop\"", highScore: 120, highestLevel: 5, playCount: 2, lastPlayedAt: nil)
        ])
        XCTAssertTrue(csv.contains("\"Bubble, \"\"Pop\"\"\""))
    }

    func testPDFManifestHasStableFileNameAndDisclaimer() {
        let manifest = PDFExportManifest(title: "Pocket", generatedAt: Date(timeIntervalSince1970: 0), rows: [], disclaimer: "AI content is auxiliary")
        XCTAssertEqual(manifest.suggestedFileName, "PocketArcade-Scorecard.pdf")
        XCTAssertTrue(manifest.disclaimer.contains("auxiliary"))
    }

    func testLocalRAGSearchReturnsEvidenceForGameQuery() {
        let chunk = RAGChunk(id: "guide-brick", title: "磚塊爆破 攻略", body: "清除 80% 即過關，短按加速彈。", tokens: ["磚塊", "攻略", "解鎖"], sourceName: "seed", sourceURL: "local://seed", fetchedAt: Date(timeIntervalSince1970: 0), licenseNote: "local seed")
        let results = LocalRAGSearchService(chunks: [chunk]).search("磚塊 攻略", limit: 1)
        XCTAssertEqual(results.first?.chunk.id, "guide-brick")
    }
}
