import Foundation
#if canImport(Network)
import Network
#endif

public enum NetworkConnectionState: Equatable, Sendable {
    case online
    case offline
    case unknown
}

public protocol NetworkStatusProviding: AnyObject {
    var currentState: NetworkConnectionState { get }
}

public struct AdReward: Equatable, Sendable {
    public let coins: Int
    public let source: String

    public init(coins: Int, source: String) {
        self.coins = coins
        self.source = source
    }
}

public protocol RewardedAdProviding: AnyObject {
    var isReady: Bool { get }
    func load() async
    func presentReward() async throws -> AdReward
}

public enum AdProviderError: Error, Equatable {
    case unavailable
}

public final class NoopRewardedAdProvider: RewardedAdProviding {
    public private(set) var isReady: Bool = false

    public init() {}

    public func load() async {
        isReady = false
    }

    public func presentReward() async throws -> AdReward {
        throw AdProviderError.unavailable
    }
}
