//
//  NetworkMonitor.swift
//  TheHotelMedia
//
//  Created by MAC on 20/09/24.
//

import Network
import SwiftUI
import Combine

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue (label: "Monitor")
    var cancellables = Set<AnyCancellable>()
    @Published var isActive = false
    @Published var isExpensive = false
    @Published var isConstrained = false
    @Published var connectionType = NWInterface.InterfaceType.other
    
    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isActive = path.status != .satisfied
                self.isExpensive = path.isExpensive
                self.isConstrained = path.isConstrained
                
                let connectionTypes: [NWInterface.InterfaceType] = [.cellular, .wifi, .wiredEthernet]
                self.connectionType = connectionTypes.first(where: path.usesInterfaceType) ?? .other
            }
        }
        monitor.start(queue: queue)
        
        $connectionType
            .sink { [weak self] type in
                guard let self else { return }
                print(type)
            }
            .store(in: &cancellables)
    }
}

