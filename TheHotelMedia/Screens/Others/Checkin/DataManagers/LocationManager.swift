//
//  LocationManager.swift
//  TheHotelMedia
//
//  Created by MAC on 01/10/24.
//

import UIKit
import CoreLocation



// Location Manager to get user's current location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var showAlert = false // Controls alert visibility
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last?.coordinate {
            DispatchQueue.main.async {
                self.currentLocation = location
                self.locationManager.stopUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location: \(error)")
    }
    
    
    func fetchAddressFromCoordinates(coordinates: CLLocationCoordinate2D, completion: @escaping (Address?) -> Void) {
        let geocoder = CLGeocoder()
        
        // Get the coordinates from the GMSPlace
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
        // Perform reverse geocoding to get address
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                print("Reverse geocoding failed: \(error?.localizedDescription ?? "No error information")")
                completion(nil)
                return
            }
            
            // Create the Address model
            let address = Address(
                street: placemark.thoroughfare,      // Street name
                city: placemark.locality,            // City name
                state: placemark.administrativeArea, // State or region
                zipCode: placemark.postalCode,       // Postal code
                country: placemark.country,          // Country
                lat: coordinates.latitude,      // Latitude from GMSPlace
                lng: coordinates.longitude      // Longitude from GMSPlace
            )
            
            // Return the address model
            completion(address)
        }
    }
    
    
    func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            requestLocation()
        case .denied, .restricted:
            showAlert = true // Show alert when permission is denied
            currentLocation = nil
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocation()
            break
        @unknown default:
            break
        }
    }
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}


extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
