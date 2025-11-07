//
//  GetPlacesResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 01/10/24.
//

import Foundation


struct GetPlacesResponse: Codable {
    let results: [Place]?
}


struct Place: Codable {
    let icon: String?
    var name: String?
    let placeID: String?
    let geometry: PlaceGeometry?
    let vicinity: String?
    let address: Address?
    
    enum CodingKeys: String, CodingKey {
        case icon
        case name
        case placeID = "place_id"
        case geometry
        case vicinity
        case address
    }
}


struct PlaceGeometry: Codable {
    let location: PlaceLocation?
}


struct PlaceLocation: Codable {
    let lat: Double?
    let lng: Double?
}
