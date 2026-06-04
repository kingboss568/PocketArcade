import Foundation

public struct ArcadeReminder: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let body: String
    public let fireDate: Date

    public init(id: String, title: String, body: String, fireDate: Date) {
        self.id = id
        self.title = title
        self.body = body
        self.fireDate = fireDate
    }
}

public protocol ReminderScheduling: AnyObject {
    func schedule(_ reminder: ArcadeReminder) async throws
    func cancel(id: String) async
}

public final class InMemoryReminderScheduler: ReminderScheduling {
    public private(set) var scheduled: [ArcadeReminder] = []

    public init() {}

    public func schedule(_ reminder: ArcadeReminder) async throws {
        scheduled.removeAll { $0.id == reminder.id }
        scheduled.append(reminder)
    }

    public func cancel(id: String) async {
        scheduled.removeAll { $0.id == id }
    }
}
