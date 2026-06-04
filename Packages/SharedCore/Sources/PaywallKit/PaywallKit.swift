import Foundation

public enum ArcadeProductID: String, CaseIterable, Codable, Sendable {
    case unlockAll = "net.boss888.pocketarcade.unlockall"
    case removeAds = "net.boss888.pocketarcade.removeads"
}

public struct EntitlementSnapshot: Equatable, Codable, Sendable {
    public var hasUnlockAll: Bool
    public var hasRemoveAds: Bool

    public init(hasUnlockAll: Bool = false, hasRemoveAds: Bool = false) {
        self.hasUnlockAll = hasUnlockAll
        self.hasRemoveAds = hasRemoveAds
    }
}

public enum EntitlementResolver {
    public static func resolve(verifiedProductIDs: Set<String>) -> EntitlementSnapshot {
        EntitlementSnapshot(
            hasUnlockAll: verifiedProductIDs.contains(ArcadeProductID.unlockAll.rawValue),
            hasRemoveAds: verifiedProductIDs.contains(ArcadeProductID.removeAds.rawValue)
        )
    }
}
