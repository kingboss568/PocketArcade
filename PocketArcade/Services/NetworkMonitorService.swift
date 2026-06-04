import Foundation
import Combine
import Network
import SharedCore

final class NetworkMonitorService: ObservableObject, NetworkStatusProviding {
    @Published private(set) var currentState: NetworkConnectionState = .unknown
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "PocketArcade.NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.currentState = path.status == .satisfied ? .online : .offline
            }
        }
        monitor.start(queue: queue)
    }
}
