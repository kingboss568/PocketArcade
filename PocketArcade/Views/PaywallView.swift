import StoreKit
import SwiftUI
import SharedCore

struct PaywallView: View {
    let highlightedGame: GameModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("UNLOCK THE CABINET").font(ArcadeTheme.headline).foregroundStyle(.white).multilineTextAlignment(.center)
                Text("解鎖 \(highlightedGame.title) 與全部 20 款遊戲。一次購買，永久保留。")
                    .font(ArcadeTheme.body).foregroundStyle(.white.opacity(0.76)).multilineTextAlignment(.center)
                VStack(spacing: 12) {
                    Button { Task { await purchase(.unlockAll) } } label: { paywallRow(title: "解鎖全部 20 款", subtitle: price(for: .unlockAll, fallback: "$2.99"), icon: "lock.open.fill") }
                    Button { Task { await purchase(.removeAds) } } label: { paywallRow(title: "去除廣告入口", subtitle: price(for: .removeAds, fallback: "$1.99"), icon: "eye.slash.fill") }
                    Button("恢復購買") { Task { await purchaseManager.restore() } }.font(.footnote.monospaced().weight(.bold))
                }
                if let status = purchaseManager.statusMessage { Text(status).font(.footnote.monospaced()).foregroundStyle(ArcadeTheme.neonYellow) }
                Text("Rewarded Ads 已以 protocol 隔離；離線時 UI 會隱藏廣告入口。正式 AdMob SDK 請在 Mac/Xcode pass 串接。")
                    .font(.caption.monospaced()).foregroundStyle(.white.opacity(0.58))
            }.padding(24)
        }.arcadeScreenBackground()
    }

    private func paywallRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.title2)
            VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline.monospaced().weight(.black)); Text(subtitle).font(.caption.monospaced()) }
            Spacer()
        }.foregroundStyle(.black).padding().background(ArcadeTheme.neonYellow, in: RoundedRectangle(cornerRadius: 18))
    }

    private func price(for id: ArcadeProductID, fallback: String) -> String { purchaseManager.product(for: id)?.displayPrice ?? fallback }

    private func purchase(_ id: ArcadeProductID) async {
        guard let product = purchaseManager.product(for: id) else {
            purchaseManager.statusMessage = "請先在 App Store Connect 建立產品：\(id.rawValue)"
            return
        }
        await purchaseManager.purchase(product)
        if purchaseManager.entitlements.hasUnlockAll || id == .removeAds { dismiss() }
    }
}
