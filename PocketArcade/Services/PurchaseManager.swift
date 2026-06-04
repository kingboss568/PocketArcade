import Foundation
import Combine
import StoreKit
import SharedCore

@MainActor
final class PurchaseManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var entitlements: EntitlementSnapshot
    @Published var statusMessage: String?

    static let productIDs = ArcadeProductID.allCases.map(\.rawValue)

    init() {
        entitlements = EntitlementSnapshot(
            hasUnlockAll: UserDefaults.standard.bool(forKey: "isPurchased"),
            hasRemoveAds: UserDefaults.standard.bool(forKey: "isAdsRemoved")
        )
    }

    func start() {
        Task { await loadProducts() }
        Task { await refreshEntitlements() }
        Task { await listenForTransactions() }
    }

    func product(for id: ArcadeProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.productIDs)
        } catch {
            statusMessage = "StoreKit 商品尚未載入：\(error.localizedDescription)"
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await refreshEntitlements()
                statusMessage = "已解鎖，歡迎回到街機廳。"
            case .success(.unverified):
                statusMessage = "購買驗證失敗，請稍後再試。"
            case .pending:
                statusMessage = "購買待核准。"
            case .userCancelled:
                statusMessage = "已取消購買。"
            @unknown default:
                statusMessage = "StoreKit 回傳未知狀態。"
            }
        } catch {
            statusMessage = "購買失敗：\(error.localizedDescription)"
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            statusMessage = "已重新同步購買項目。"
        } catch {
            statusMessage = "恢復購買失敗：\(error.localizedDescription)"
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }

    private func refreshEntitlements() async {
        var verifiedIDs: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                verifiedIDs.insert(transaction.productID)
            }
        }
        if UserDefaults.standard.bool(forKey: "isPurchased") { verifiedIDs.insert(ArcadeProductID.unlockAll.rawValue) }
        if UserDefaults.standard.bool(forKey: "isAdsRemoved") { verifiedIDs.insert(ArcadeProductID.removeAds.rawValue) }
        entitlements = EntitlementResolver.resolve(verifiedProductIDs: verifiedIDs)
        UserDefaults.standard.set(entitlements.hasUnlockAll, forKey: "isPurchased")
        UserDefaults.standard.set(entitlements.hasRemoveAds, forKey: "isAdsRemoved")
    }
}
