//
//  GyroManager.swift
//  TheHotelMedia
//
//  Created by MAC on 26/03/25.
//

import SwiftUI
import CoreMotion
import Combine

class GyroManager: ObservableObject {
    private var motionManager = CMMotionManager()
    var rotationRate: CurrentValueSubject<CMRotationRate, Never>  = .init(CMRotationRate(x: 0, y: 0, z: 0))

    init() {
        startGyroUpdates()
    }

    func startGyroUpdates() {
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1 // Adjust update frequency as needed
            motionManager.startGyroUpdates(to: .main) { [weak self] (data, error) in
                guard let self = self, let data = data else { return }
                DispatchQueue.main.async {
                    self.rotationRate.send(data.rotationRate)
                }
            }
        }
    }

    func stopGyroUpdates() {
        motionManager.stopGyroUpdates()
    }
}

