//
//  CompassHeading.swift
//  TheHotelMedia
//
//  Created by MAC on 25/03/25.
//

import SwiftUI
import Combine
import CoreLocation

class CompassHeading: NSObject, ObservableObject, CLLocationManagerDelegate {
    var objectWillChange = PassthroughSubject<Void, Never>()
    
    var degrees: CurrentValueSubject<Double, Never> = .init(.zero)
    
    private let locationManager = CLLocationManager()
    private var lastReportedHeading: Double = .zero
    private var accumulatedRotation: Double = .zero  // Tracks continuous rotation
    
    override init() {
        super.init()
        locationManager.delegate = self
        setup()
    }
    
    private func setup() {
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let newDegrees = newHeading.magneticHeading
        accumulatedRotation += shortestRotation(from: lastReportedHeading, to: newDegrees)
        lastReportedHeading = newDegrees
        self.degrees.send(accumulatedRotation)
    }
    
    private func shortestRotation(from oldAngle: Double, to newAngle: Double) -> Double {
        let difference = newAngle - oldAngle
        
        if difference > 180 {
            return difference - 360
        } else if difference < -180 {
            return difference + 360
        } else {
            return difference
        }
    }
}

