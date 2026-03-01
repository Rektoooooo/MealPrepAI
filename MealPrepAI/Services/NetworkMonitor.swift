import Foundation
import Network

@MainActor
@Observable
final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private(set) var isConnected: Bool = true
    private(set) var connectionType: NWInterface.InterfaceType?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let newConnected = path.status == .satisfied
                if newConnected != self.isConnected {
                    self.isConnected = newConnected
                }
                let newType: NWInterface.InterfaceType?
                if path.usesInterfaceType(.wifi) {
                    newType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    newType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    newType = .wiredEthernet
                } else {
                    newType = nil
                }
                if newType != self.connectionType {
                    self.connectionType = newType
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
