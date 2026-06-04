import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

public enum AIUnavailableMessage {
    public static let text = "AI 功能目前不可用"
}

public enum AIAvailabilityStatus: Equatable, Sendable {
    case available
    case unavailable(reason: String)
}

public struct AICoachRequest: Equatable, Sendable {
    public let gameTitle: String
    public let recentScore: Int
    public let question: String

    public init(gameTitle: String, recentScore: Int, question: String) {
        self.gameTitle = gameTitle
        self.recentScore = recentScore
        self.question = question
    }
}

public struct AICoachResponse: Equatable, Sendable {
    public let text: String
    public let evidenceIDs: [String]
    public let isFallback: Bool

    public init(text: String, evidenceIDs: [String], isFallback: Bool) {
        self.text = text
        self.evidenceIDs = evidenceIDs
        self.isFallback = isFallback
    }
}

public protocol ArcadeCoachProviding: Sendable {
    func availability() -> AIAvailabilityStatus
    func answer(_ request: AICoachRequest, evidence: [String]) async -> AICoachResponse
}

public struct FoundationModelsArcadeCoach: ArcadeCoachProviding {
    public init() {}

    public func availability() -> AIAvailabilityStatus {
        #if canImport(FoundationModels)
        return .unavailable(reason: "Foundation Models API wiring 留給 Mac/Xcode pass，確保本 Windows 交付不引用不可驗證 API。")
        #else
        return .unavailable(reason: "目前建置環境沒有 Foundation Models framework。")
        #endif
    }

    public func answer(_ request: AICoachRequest, evidence: [String]) async -> AICoachResponse {
        switch availability() {
        case .available:
            return AICoachResponse(
                text: "根據本機攻略資料，先穩定連段再追求高風險加速。",
                evidenceIDs: evidence,
                isFallback: false
            )
        case .unavailable:
            return AICoachResponse(text: AIUnavailableMessage.text, evidenceIDs: evidence, isFallback: true)
        }
    }
}
