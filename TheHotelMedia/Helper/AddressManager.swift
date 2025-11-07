//
//  AddressManager.swift
//  TheHotelMedia
//
//  Created by MAC on 01/10/24.
//

import Foundation
import GooglePlaces


class AddressManager {
    
    static let shared = AddressManager()
    
    func fetchAddressFromGMSPlace(place: GMSPlace, completion: @escaping (Address?) -> Void) {
        let geocoder = CLGeocoder()
        
        // Get the coordinates from the GMSPlace
        let location = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        
        // Perform reverse geocoding to get address
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                print("Reverse geocoding failed: \(error?.localizedDescription ?? "No error information")")
                completion(nil)
                return
            }
            
            var street: String = ""
            
            if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
                street = thoroughfare
            } else {
                street = place.name ?? ""
            }
            
            
            // Create the Address model
            let address = Address(
                street: street,                      // Street name
                city: placemark.locality,            // City name
                state: placemark.administrativeArea, // State or region
                zipCode: placemark.postalCode,       // Postal code
                country: placemark.country,          // Country
                lat: place.coordinate.latitude,      // Latitude from GMSPlace
                lng: place.coordinate.longitude      // Longitude from GMSPlace
            )
            
            // Return the address model
            completion(address)
        }
    }
    
    
    func fetchAddressFromPlace(place: Place, completion: @escaping (Address?) -> Void) {
        let geocoder = CLGeocoder()
        
        // Get the coordinates from the GMSPlace
        let location = CLLocation(latitude: place.geometry?.location?.lat ?? 0, longitude: place.geometry?.location?.lng ?? 0)
        
        // Perform reverse geocoding to get address
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                print("Reverse geocoding failed: \(error?.localizedDescription ?? "No error information")")
                completion(nil)
                return
            }
            
            var street: String = ""
            
            if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
                street = thoroughfare
            } else {
                street = place.name ?? ""
            }
            
            print(placemark)
            
            // Create the Address model
            let address = Address(
                street: street,                      // Street name
                city: placemark.locality,            // City name
                state: placemark.administrativeArea, // State or region
                zipCode: placemark.postalCode,       // Postal code
                country: placemark.country,          // Country
                lat: place.geometry?.location?.lat ?? 0,       // Latitude from Place
                lng: place.geometry?.location?.lng ?? 0        // Longitude from Place
            )
            
            // Return the address model
            completion(address)
        }
    }
}
