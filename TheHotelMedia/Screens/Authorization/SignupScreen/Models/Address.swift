//
//  Address.swift
//  TheHotelMedia
//
//  Created by MAC on 24/09/24.
//

import Foundation

struct Address: Codable, Equatable, Hashable {
    var street: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String?
    var lat: Double
    var lng: Double
}
