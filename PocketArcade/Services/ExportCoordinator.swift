import Foundation
import PDFKit
import UIKit
import SharedCore

struct ExportCoordinator {
    func csv(rows: [ArcadeScoreExportRow]) -> String {
        CSVExportService().makeCSV(rows: rows)
    }

    func pdfData(rows: [ArcadeScoreExportRow]) -> Data {
        let manifest = PDFExportManifest(
            title: "Pocket Arcade Scorecard",
            generatedAt: .now,
            rows: rows,
            disclaimer: "遊戲分數與進度僅供娛樂紀錄。AI 攻略僅為輔助資訊，不構成專業意見。"
        )
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        return renderer.pdfData { context in
            context.beginPage()
            let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 24)]
            manifest.title.draw(at: CGPoint(x: 48, y: 48), withAttributes: titleAttributes)
            var y: CGFloat = 96
            let bodyAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)]
            for row in rows {
                let line = "\(row.gameTitle) | High \(row.highScore) | Level \(row.highestLevel) | Plays \(row.playCount)"
                line.draw(at: CGPoint(x: 48, y: y), withAttributes: bodyAttributes)
                y += 24
            }
            manifest.disclaimer.draw(at: CGPoint(x: 48, y: 720), withAttributes: bodyAttributes)
        }
    }
}
