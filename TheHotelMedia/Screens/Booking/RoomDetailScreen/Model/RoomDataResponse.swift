//
//  RoomDataResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 20/02/25.
//

import Foundation

// MARK: - RoomDataResponse
struct RoomDataResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: RoomData?
}

// MARK: - DataClass
struct RoomData: Codable {
    let id, bedType: String?
    let adults, children, maxOccupancy: Int?
    let availability: Bool?
    let amenities: [String]?
    let roomType, businessProfileID, title, description: String?
    let pricePerNight: Double?
    let currency, mealPlan, createdAt, checkIn: String?
    let checkOut: String?
    let languageSpoken: [LanguageSpoken]?
    let roomImagesRef: [Cover]?
    let cover: Cover?
    let amenitiesRef: [AmenitiesRef]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case bedType, adults, children, maxOccupancy, availability, amenities, roomType, businessProfileID, title, description, pricePerNight, currency, mealPlan, createdAt, checkIn, checkOut, languageSpoken, roomImagesRef, cover, amenitiesRef
    }
}


// MARK: - LanguageSpoken
struct LanguageSpoken: Codable, Identifiable {
    let name: String?
    let flag: String?
    let id, createdAt, updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case name, flag
        case id = "_id"
        case createdAt, updatedAt
    }
}
